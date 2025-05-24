module Bristow
  module Providers
    class Openai < Base
      def initialize(api_key:)
        super
        @client = OpenAI::Client.new(access_token: api_key)
      end

      def chat(params)
        response = @client.chat(parameters: params)
        response.dig("choices", 0, "message")
      end

      def stream_chat(params, &block)
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

      def format_functions(functions)
        {
          functions: functions.map(&:to_schema),
          function_call: "auto"
        }
      end

      def default_model
        "gpt-4o-mini"
      end

      def is_function_call?(response)
        response["function_call"]
      end

      def function_name(response)
        response["function_call"]["name"]
      end

      def function_arguments(response)
        JSON.parse(response["function_call"]["arguments"])
      end

      def format_function_response(response, result)
        message_hash = {
          "role" => "function",
          "name" => response["function_call"]["name"],
          "content" => result.to_json
        }
      end
    end
  end
end
