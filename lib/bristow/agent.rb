require 'openai'
require 'logger'
require 'json'

module Bristow
  class Agent
    attr_reader :name, :description, :functions, :system_message, :chat_history

    def initialize(name:, description:, system_message: nil, functions: [], model: Bristow.configuration.default_model)
      @name = name
      @description = description
      @system_message = system_message
      @functions = functions
      @logger = Bristow.configuration.logger
      @client = Bristow.configuration.client
      @model = model
      @chat_history = []
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
      messages = messages.dup
      messages.unshift(system_message_hash) if system_message

      @chat_history = messages.dup

      loop do
        params = {
          model: @model,
          messages: messages
        }

        if functions.any?
          params[:functions] = functions_for_openai
          params[:function_call] = "auto"
        end

        response_message = if block_given?
          handle_streaming_chat(params, &block)
        else
          response = @client.chat(parameters: params)
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
      @logger.error("Error calling OpenAI API: #{e.response[:body]}")
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
      @client.chat(parameters: params)

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
end
