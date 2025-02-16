module Bristow
  module Terminations
    class CanNotStopWillNotStop < Bristow::Termination
      def continue?(_messages)
        true
      end
    end
  end
end
