#gem 'httparty', '=0.5.2'
require 'httparty'
require 'hashie'
require 'json'
require 'ostruct'

module Wordstream

  class Client
    include HTTParty
    base_uri 'http://api.wordstream.com'
    default_params :callback => 'response'

    attr_accessor :username, :password
    def initialize(username, password)
      @username, @password = username, password
    end

    def login
      resp = self.class.get('/authentication/login', :query => {:username => @username, :password => @password})
      parsed = response(resp)
      self.class.default_params :session_id => parsed.data.session_id
    end

    def logout
      response( self.class.get('/authentication/logout') )
    end

    def get_api_credits
      response(self.class.get('/authentication/get_api_credits'))
    end

    def response(resp)
      Hashie::Mash.new (JSON.parse( resp.match(/response\((.*)\)/)[1]) )
    end
  end

  class KeywordTool
    attr_accessor :client, :seeds
    attr_reader :keywords, :niches
    def initialize(client, seeds)
      @client, @seeds = client, seeds
    end

    def get_keyword_niches(max_niches)
      resp = @client.response( @client.class.get('/keywordtool/get_keyword_niches', :query => {:seeds => @seeds, :max_niches => max_niches}) )
      @niches = resp.data
      @niches = resp.data.groupings.collect do |g|
        keywords = g.matches.collect { |m| Keyword.new(:keyword => resp.data.keywords[m][0], :volume => resp.data.keywords[m][1]) }
        Niche.new(
          :title    => g.title,
          :score    => g.score,
          :wordlist => g.wordlist,
          :keywords => keywords
        )
      end
    end

    def get_keywords(max_results)
      resp = @client.response( @client.class.get('/keywordtool/get_keywords', :query => {:seeds => @seeds, :max_results => max_results}) )
      @keywords = resp.data.collect { |k| Keyword.new(:keyword => k[0], :volume => k[1]) }
    end
  end

  class Keyword < OpenStruct
  end
end
