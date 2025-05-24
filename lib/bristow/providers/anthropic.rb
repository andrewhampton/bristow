module Bristow
  module Providers
    class Anthropic < Base
      def initialize(api_key:)
        super
        @client = ::Anthropic::Client.new(api_key: api_key)
      end

      def chat(params)
        # Convert messages format for Anthropic
        anthropic_params = convert_params(params)

        response = @client.messages.create(anthropic_params)

        # Convert response back to standard format
        if response.content.any? { |content| content.type == "tool_use" }
          # Handle tool use response
          tool_use = response.content.find { |content| content.type == "tool_use" }
          {
            "role" => "assistant",
            "function_call" => {
              "name" => tool_use.name,
              "arguments" => tool_use.input.to_json
            }
          }
        else
          # Handle text response
          text_content = response.content.find { |content| content.type == "text" }&.text || ""
          {
            "role" => "assistant",
            "content" => text_content
          }
        end
      end

      def stream_chat(params, &block)
        anthropic_params = convert_params(params)

        full_content = ""
        tool_use = {}
        tool_use_content_json = ""

        stream = @client.messages.stream_raw(anthropic_params)
        stream.each do |event|
          case event.type
          when :content_block_delta
            if event.delta.type == :text_delta
              text = event.delta.text
              full_content += text
              yield text if block_given?
            elsif event.delta.type == :input_json_delta
              # Accumulate tool input JSON fragments
              tool_use_content_json += event.delta.partial_json || ""
            end
          when :content_block_start
            if event.content_block.type == :tool_use
              tool_use = event.content_block
            end
          end
        end

        if tool_use.to_hash.any?
          {
            "role" => "assistant",
            content: [tool_use.to_hash.merge({input: JSON.parse(tool_use_content_json)})]
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
          tools: functions.map { |func| convert_function_to_tool(func.to_schema) }
        }
      end

      def is_function_call?(response)
        response.dig(:content, 0, :type) == :tool_use
      end

      def function_name(response)
        # TODO: support parallel function calls
        response[:content][0][:name]
      end

      def function_arguments(response)
        # TODO: support parallel function calls
        response[:content][0][:input]
      end

      def format_function_response(response, result)
        {
          role: :user,
          content: [{
            type: "tool_result",
            tool_use_id: response[:content][0][:id],
            content: result.to_json
          }]
        }
      end

      def default_model
        "claude-3-5-sonnet-20241022"
      end

      private

      def convert_params(params)
        # Extract system messages and regular messages
        messages = params[:messages] || []
        system_messages = messages.select { |msg| msg["role"] == "system" || msg[:role] == "system" }
        other_messages = messages.reject { |msg| msg["role"] == "system" || msg[:role] == "system" }

        anthropic_params = {
          model: params[:model] || default_model,
          max_tokens: params[:max_tokens] || 1024,
          messages: convert_messages(other_messages)
        }

        # Add system message if present
        if system_messages.any?
          anthropic_params[:system] = system_messages.map { |msg| msg["content"] || msg[:content] }.join("\n")
        end

        # Add tools if present
        if params[:tools]
          anthropic_params[:tools] = params[:tools]
        elsif params[:functions]
          anthropic_params[:tools] = params[:functions].map { |func| convert_function_to_tool(func) }
        end

        anthropic_params
      end

      def convert_messages(messages)
        messages.map do |msg|
          role = msg["role"] || msg[:role]
          case role
          when "function"
            # Convert function result to user message
            {
              "role" => "user",
              "content" => "Function result: #{msg['content'] || msg[:content]}"
            }
          else
            # Handle regular user/assistant messages
            function_call = msg["function_call"] || msg[:function_call]
            if function_call
              # Convert function call to tool use format
              {
                "role" => "assistant",
                "content" => [
                  {
                    "type" => "tool_use",
                    "id" => "call_#{rand(1000000)}",
                    "name" => function_call["name"] || function_call[:name],
                    "input" => JSON.parse(function_call["arguments"] || function_call[:arguments])
                  }
                ]
              }
            else
              {
                "role" => role,
                "content" => msg["content"] || msg[:content]
              }
            end
          end
        end
      end

      def convert_function_to_tool(func_schema)
        {
          "name" => func_schema[:name],
          "description" => func_schema[:description],
          "input_schema" => func_schema[:parameters]
        }
      end
    end
  end
end
