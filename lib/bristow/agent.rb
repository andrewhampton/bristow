module Bristow
  class Agent
    include Bristow::Sgetter

    sgetter :name
    sgetter :description
    sgetter :system_message
    sgetter :functions, default: []
    sgetter :model, default: -> { Bristow.configuration.model }
    sgetter :client, default: -> { Bristow.configuration.client }
    sgetter :logger, default: -> { Bristow.configuration.logger }
    sgetter :termination, default: -> { Bristow::Terminations::MaxMessages.new(100) }
    attr_reader :chat_history

    def initialize(
      name: self.class.name,
      description: self.class.name,
      system_message: self.class.system_message,
      functions: self.class.functions.dup,
      model: self.class.model,
      client: self.class.client,
      logger: self.class.logger,
      termination: self.class.termination
    )
      @name = name
      @description = description
      @system_message = system_message
      @functions = functions
      @model = model
      @client = client
      @logger = logger
      @chat_history = []
      @termination = termination
    end

    def handle_function_call(name, arguments)
      function = functions.find { |f| f.name == name }
      raise ArgumentError, "Function #{name} not found" unless function
      function.call(**arguments.transform_keys(&:to_sym))
    end

    def functions_for_openai
      functions.map(&:to_openai_schema)
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
          params[:functions] = functions_for_openai
          params[:function_call] = "auto"
        end

        logger.debug("Calling OpenAI API with params: #{params}")
        response_message = if block_given?
          handle_streaming_chat(params, &block)
        else
          response = client.chat(parameters: params)
          response.dig("choices", 0, "message")
        end

        messages << response_message
        @chat_history << response_message

        # If there's no function call, we're done
        break unless response_message["function_call"]

        # Handle the function call and add its result to the messages
        result = handle_function_call(
          response_message["function_call"]["name"],
          JSON.parse(response_message["function_call"]["arguments"])
        )

        yield "\n[Function Call: #{response_message["function_call"]["name"]}]\n" if block_given?
        yield "#{result.to_json}\n" if block_given?

        messages << {
          "role" => "function",
          "name" => response_message["function_call"]["name"],
          "content" => result.to_json
        }
      end

      messages
    rescue Faraday::BadRequestError, Faraday::ResourceNotFound => e
      logger.error("Error calling OpenAI API: #{e.response[:body]}")
      raise
    end

    private

    def handle_streaming_chat(params)
      full_content = ""
      function_name = nil
      function_args = ""

      stream_proc = proc do |chunk|
        delta = chunk.dig("choices", 0, "delta")
        next unless delta

        if delta["function_call"]
          # Building function call
          if delta.dig("function_call", "name")
            function_name = delta.dig("function_call", "name")
          end

          if delta.dig("function_call", "arguments")
            function_args += delta.dig("function_call", "arguments")
          end
        elsif delta["content"]
          # Regular content
          full_content += delta["content"]
          yield delta["content"]
        end
      end

      params[:stream] = stream_proc
      client.chat(parameters: params)

      if function_name
        {
          "role" => "assistant",
          "function_call" => {
            "name" => function_name,
            "arguments" => function_args
          }
        }
      else
        {
          "role" => "assistant",
          "content" => full_content
        }
      end
    end

    def system_message_hash
      {
        "role" => "system",
        "content" => system_message
      }
    end
  end
end
