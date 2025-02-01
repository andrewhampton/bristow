module Bristow
  module Delegate
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def delegate(*methods, to:)
        methods.each do |method|
          define_method(method) do
            send(to).send(method)
          end
        end
      end
    end
  end
end
