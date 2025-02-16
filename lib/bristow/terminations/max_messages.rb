module Bristow
  module Terminations
    class MaxMessages < Bristow::Termination
      def initialize(max_messages)
        @max_messages = max_messages
      end

      def continue?(messages)
        messages.size < @max_messages
      end
    end
  end
end
