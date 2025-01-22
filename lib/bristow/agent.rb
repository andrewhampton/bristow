require 'openai'
require 'logger'

module Bristow
  class Agent
    attr_reader :name, :description, :functions, :system_message

    def initialize(name:, description:, system_message: nil, functions: [])
      @name = name
      @description = description
      @system_message = system_message
      @functions = functions
      @logger = Bristow.configuration.logger
      @client = Bristow.configuration.client
    end

    def handle_function_call(name, arguments)
      function = functions.find { |f| f.name == name }
      raise ArgumentError, "Function #{name} not found" unless function
      function.call(**arguments.transform_keys(&:to_sym))
    end

    def functions_for_openai
      functions.map do |function|
        {
          name: function.name,
          description: function.description,
          parameters: {
            type: "object",
            properties: function.parameters.transform_values { |type| parameter_type_for(type) },
            required: function.parameters.keys.map(&:to_s)
          }
        }
      end
    end

    def chat(messages, &block)
      messages = [system_message_hash] + messages if system_message

      params = {
        model: Bristow.configuration.default_model,
        messages: messages
      }

      params[:functions] = functions_for_openai if functions.any?
      params[:function_call] = "auto" if functions.any?

      if block_given?
        streamed_message = handle_streaming_chat(params, &block)
        messages + [streamed_message]
      else
        response = @client.chat(parameters: params)
        message = response.dig("choices", 0, "message")
        handle_chat_message(message, messages)
      end

    rescue Faraday::BadRequestError => e
      @logger.error("Error calling OpenAI API: #{e.response[:body]}")
    end

    private

    def handle_streaming_chat(params)
      full_content = ""
      function_name = nil
      function_args = ""
      streaming_finished = false

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

        if chunk.dig("choices", 0, "finish_reason")
          streaming_finished = true
        end
      end

      params[:stream] = stream_proc
      @client.chat(parameters: params)

      # Wait for streaming to complete
      until streaming_finished
        sleep 0.1
      end

      if function_name
        # Handle the complete function call
        result = handle_function_call(
          function_name,
          JSON.parse(function_args)
        )

        yield "\n[Function Call: #{function_name}]\n"
        yield result.to_s

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

    def handle_chat_message(message, messages)
      function_call = message["function_call"]

      if function_call
        result = handle_function_call(
          function_call["name"],
          JSON.parse(function_call["arguments"])
        )

        messages + [
          message,
          {
            "role" => "function",
            "name" => function_call["name"],
            "content" => result.to_s
          }
        ]
      else
        messages + [message]
      end
    end

    def system_message_hash
      {
        "role" => "system",
        "content" => system_message
      }
    end

    def parameter_type_for(type)
      case type.to_s
      when "Integer", "Fixnum"
        { type: "integer" }
      when "Float"
        { type: "number" }
      when "String"
        { type: "string" }
      when "TrueClass", "FalseClass", "Boolean"
        { type: "boolean" }
      else
        { type: "string" }
      end
    end
  end

  class Function
    attr_reader :name, :description, :parameters

    def initialize(name:, description:, parameters: {}, &block)
      @name = name
      @description = description
      @parameters = parameters
      @block = block
    end

    def call(**args)
      @block.call(**args)
    end
  end
end
