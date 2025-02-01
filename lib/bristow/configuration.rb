module Bristow
  class Configuration
    attr_accessor :openai_api_key, :default_model, :logger
    attr_reader :client

    def initialize
      @openai_api_key = ENV['OPENAI_API_KEY']
      @default_model = 'gpt-4o-mini'
      @logger = Logger.new(STDOUT)
      reset_client
    end

    def openai_api_key=(key)
      @openai_api_key = key
      reset_client
    end

    private

    def reset_client
      @client = OpenAI::Client.new(access_token: @openai_api_key)
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
