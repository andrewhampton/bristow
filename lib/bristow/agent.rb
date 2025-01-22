require 'openai'
require 'logger'

module Bristow
  class Agent
    attr_reader :name, :description, :functions, :system_message

    def initialize(name:, description:, system_message: nil, functions: [], logger: Logger.new(STDOUT))
      @name = name
      @description = description
      @system_message = system_message
      @functions = functions
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      @logger = logger
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

    def chat(messages)
      messages = [system_message_hash] + messages if system_message

      params = {
        model: "gpt-4",
        messages: messages
      }

      params[:functions] = functions_for_openai if functions.any?
      params[:function_call] = "auto" if functions.any?

      response = @client.chat(parameters: params)

      message = response.dig("choices", 0, "message")
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

    rescue Faraday::BadRequestError => e
      @logger.error("Error calling OpenAI API: #{e.response[:body]}")
    end

    private

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
