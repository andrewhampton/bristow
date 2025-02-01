# frozen_string_literal: true

module Bristow
  class Function
    include Bristow::Sgetter
    include Bristow::Delegate

    sgetter :name
    sgetter :description
    sgetter :parameters, default: {}

    def self.to_openai_schema
      {
        name: name,
        description: description,
        parameters: parameters
      }
    end
    delegate :to_openai_schema, to: :class

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
