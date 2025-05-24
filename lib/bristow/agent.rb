module Bristow
  class Agent
    include Bristow::Sgetter

    sgetter :agent_name
    sgetter :description
    sgetter :system_message
    sgetter :functions, default: []
    sgetter :provider, default: -> { Bristow.configuration.default_provider }
    sgetter :model, default: -> { Bristow.configuration.model }
    sgetter :client, default: nil
    sgetter :logger, default: -> { Bristow.configuration.logger }
    sgetter :termination, default: -> { Bristow::Terminations::MaxMessages.new(100) }
    attr_reader :chat_history



    def initialize(
      agent_name: self.class.agent_name,
      description: self.class.description,
      system_message: self.class.system_message,
      functions: self.class.functions.dup,
      provider: self.class.provider,
      model: self.class.model,
      client: self.class.client,
      logger: self.class.logger,
      termination: self.class.termination
    )
      @agent_name = agent_name
      @description = description
      @system_message = system_message
      @functions = functions
      @provider = provider
      @model = model
      @client = client || Bristow.configuration.client_for(@provider)
      @logger = logger
      @chat_history = []
      @termination = termination
    end

    def handle_function_call(name, arguments)
      function = functions.find { |f| f.function_name == name }
      raise ArgumentError, "Function #{name} not found" unless function
      function.call(**arguments.transform_keys(&:to_sym))
    end

    def formatted_functions
      client.format_functions(functions)
    end

    def self.chat(...)
      new.chat(...)
    end

    def chat(messages, &block)
      # Convert string message to proper format
      messages = [{ role: "user", content: messages }] if messages.is_a?(String)

      messages = messages.dup
      messages.unshift(system_message_hash) if system_message

      @chat_history = messages.dup

      while termination.continue?(messages) do
        params = {
          model: model,
          messages: messages
        }

        if functions.any?
          params.merge!(formatted_functions)
        end

        logger.debug("Calling #{provider} API with params: #{params}")
        response_message = if block_given?
          client.stream_chat(params, &block)
        else
          client.chat(params)
        end

        messages << response_message
        @chat_history << response_message

        # If there's no function call, we're done
        break unless client.is_function_call?(response_message)

        # Handle the function call and add its result to the messages
        result = handle_function_call(
          client.function_name(response_message),
          client.function_arguments(response_message)
        )

        yield "\n[Function Call: #{response_message}]\n" if block_given?
        yield "#{result.to_json}\n" if block_given?


        messages << client.format_function_response(response_message, result)
      end

      messages
    rescue Faraday::BadRequestError, Faraday::ResourceNotFound => e
      logger.error("Error calling OpenAI API: #{e.response[:body]}")
      raise
    end

    private



    def system_message_hash
      {
        "role" => "system",
        "content" => system_message
      }
    end
  end
end
