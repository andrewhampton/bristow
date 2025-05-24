# frozen_string_literal: true

module Bristow
  class Function
    include Bristow::Sgetter
    include Bristow::Delegate

    sgetter :function_name, default: nil
    sgetter :description
    sgetter :parameters, default: {}

    def initialize(
      function_name: self.class.function_name,
      description: self.class.description,
      parameters: self.class.parameters
    )
      @function_name = function_name
      @description = description
      @parameters = parameters
    end

    def self.to_schema
      {
        name: function_name,
        description: description,
        parameters: parameters
      }
    end
    delegate :to_schema, to: :class

    def self.call(...)
      new.call(...)
    end

    def call(**kwargs)
      validation_errors = validate_required_parameters!(kwargs)
      return validation_errors unless validation_errors.nil?
      perform(**kwargs)
    end

    def perform(...)
      raise NotImplementedError, "#{self.class.name}#perform must be implemented"
    end

    private

    def validate_required_parameters!(kwargs)
      required_params = self.class.parameters.dig(:required) || []
      missing = required_params.map(&:to_sym) - kwargs.keys.map(&:to_sym)
      "missing parameters: #{missing.inspect}" if missing.any?
    end
  end
end
