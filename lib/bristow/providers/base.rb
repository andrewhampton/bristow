module Bristow
  module Providers
    class Base
      attr_reader :api_key

      def initialize(api_key:)
        @api_key = api_key
        raise ArgumentError, "API key is required" if api_key.nil? || api_key.empty?
      end

      # Abstract method - must be implemented by subclasses
      def chat(params)
        raise NotImplementedError, "Subclasses must implement #chat"
      end

      # Abstract method - must be implemented by subclasses
      def stream_chat(params, &block)
        raise NotImplementedError, "Subclasses must implement #stream_chat"
      end

      # Abstract method - must be implemented by subclasses
      def format_functions(functions)
        raise NotImplementedError, "Subclasses must implement #format_functions"
      end

      # Abstract method - must be implemented by subclasses
      def default_model
        raise NotImplementedError, "Subclasses must implement #default_model"
      end

      def is_function_call?(response)
        raise NotImplementedError, "Subclasses must implement #is_function_call?"
      end

      def function_name(response)
        raise NotImplementedError, "Subclasses must implement #function_name"
      end

      def function_arguments(response)
        raise NotImplementedError, "Subclasses must implement #function_arguments"
      end

      def format_function_response(response, result)
        raise NotImplementedError, "Subclasses must implement #format_function_response"
      end

    end
  end
end
