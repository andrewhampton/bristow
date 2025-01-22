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
    end

    def call(**kwargs)
      validate_parameters!(kwargs)
      @block.call(**kwargs)
    end

    def to_openai_schema
      {
        name: name,
        description: description,
        parameters: {
          type: "object",
          properties: parameters_schema,
          required: required_parameters
        }
      }
    end

    private

    def validate_parameters!(kwargs)
      # Check for missing required parameters
      missing = required_parameters - kwargs.keys
      raise ArgumentError, "missing keyword: :#{missing.first}" if missing.any?

      # Check parameter types
      kwargs.each do |key, value|
        expected_type = parameters[key].is_a?(Hash) ? parameters[key][:type] : parameters[key]
        next unless expected_type.is_a?(Class) # Skip complex type definitions

        unless value.is_a?(expected_type)
          raise TypeError, "#{key} must be a #{expected_type}"
        end
      end
    end

    def parameters_schema
      parameters.transform_values do |type|
        if type.is_a?(Hash)
          { type: ruby_type_to_json_type(type[:type]) }
        else
          { type: ruby_type_to_json_type(type) }
        end
      end
    end

    def required_parameters
      parameters.reject { |_, type| type.is_a?(Hash) && type[:optional] }.keys
    end

    def ruby_type_to_json_type(type)
      case type
      when String, Class
        case type.to_s
        when "String" then "string"
        when "Integer" then "integer"
        when "Float" then "number"
        when "TrueClass", "FalseClass", "Boolean" then "boolean"
        when "Array" then "array"
        when "Hash" then "object"
        else "string" # Default to string for unknown types
        end
      else
        "string" # Default to string for unknown types
      end
    end
  end
end
