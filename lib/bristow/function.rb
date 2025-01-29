# frozen_string_literal: true

module Bristow
  class Function
    attr_reader :name, :description, :parameters

    def initialize(name:, description:, parameters:, &block)
      raise ArgumentError, "block is required" unless block_given?
      @name = name
      @description = description
      @parameters = parameters
      @block = block

      if !parameters.has_key?(:type)
        parameters[:type] = "object"
      end
    end

    def call(**kwargs)
      validate_required_parameters!(kwargs)
      @block.call(**kwargs)
    end

    def to_openai_schema
      {
        name: name,
        description: description,
        parameters: parameters
      }
    end

    private

    def validate_required_parameters!(kwargs)
      required_params = parameters.dig(:required) || []
      missing = required_params.map(&:to_sym) - kwargs.keys.map(&:to_sym)
      raise ArgumentError, "missing keyword: #{missing.first}" if missing.any?
    end
  end
end
