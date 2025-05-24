module Bristow
  class Configuration
    attr_accessor :openai_api_key, :anthropic_api_key, :google_api_key, 
                  :default_provider, :default_model, :logger
    attr_reader :clients

    def initialize
      @openai_api_key = ENV['OPENAI_API_KEY']
      @anthropic_api_key = ENV['ANTHROPIC_API_KEY']
      @google_api_key = ENV['GOOGLE_API_KEY']
      @default_provider = :openai
      @default_model = nil  # Will use provider's default
      @logger = Logger.new(STDOUT)
      @clients = {}
    end

    def openai_api_key=(key)
      @openai_api_key = key
      reset_client(:openai)
    end

    def anthropic_api_key=(key)
      @anthropic_api_key = key
      reset_client(:anthropic)
    end

    def google_api_key=(key)
      @google_api_key = key
      reset_client(:google)
    end

    def client_for(provider)
      @clients[provider] ||= build_client_for(provider)
    end

    # Backward compatibility
    def client
      client_for(default_provider)
    end

    # Backward compatibility  
    def model
      @default_model || client_for(default_provider).default_model
    end

    def model=(model)
      @default_model = model
    end

    private

    def build_client_for(provider)
      case provider
      when :openai
        raise ArgumentError, "OpenAI API key not configured" unless @openai_api_key
        Providers::Openai.new(api_key: @openai_api_key)
      when :anthropic
        raise ArgumentError, "Anthropic API key not configured" unless @anthropic_api_key
        Providers::Anthropic.new(api_key: @anthropic_api_key)
      when :google
        raise ArgumentError, "Google API key not configured" unless @google_api_key
        Providers::Google.new(api_key: @google_api_key)
      else
        raise ArgumentError, "Unknown provider: #{provider}"
      end
    end

    def reset_client(provider)
      @clients.delete(provider)
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
