module Bristow
  module Terminations
    class Timeout < Bristow::Termination
      def initialize(end_time: Time.now + 60)
        @end_time = end_time
      end

      def continue?(_messages)
        Time.now < @end_time
      end
    end
  end
end
