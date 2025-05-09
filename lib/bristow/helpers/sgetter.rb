# A helper to define a getter/setter method
# This will let you define a class level getter/setter method with an instance reader
#
# Example:
# class Agent
#   include Bristow::Sgetter
#   sgetter :agent_name
#   sgetter :model, default: -> { Bristow.configuration.model }
# end
#
# class Sydney < Agent
#   agent_name 'Sydney'
# end
#
# sydney = Sydney.new
# sydney.agent_name # => 'Sydney'
module Bristow
  module Sgetter
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sgetter(attr, default: nil)
        # Define the method that allows for both getter/setter syntax
        define_singleton_method(attr) do |val = nil|
          if val.nil?
            return instance_variable_get("@#{attr}") if instance_variable_defined?("@#{attr}")
            default.respond_to?(:call) ? default.call : default
          else
            instance_variable_set("@#{attr}", val)
          end
        end

        # Instance-level reader
        define_method(attr) do
          instance_variable_get("@#{attr}")
        end
      end
    end
  end
end
