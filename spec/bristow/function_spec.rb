# frozen_string_literal: true

RSpec.describe Bristow::Function do
  let(:name) { "test_function" }
  let(:description) { "A test function" }
  let(:parameters) { { param1: String, param2: Integer, param3: { type: String, optional: true } } }
  let(:block) { ->(param1:, param2:, param3: nil) { { result: [param1, param2, param3] } } }

  subject(:function) do
    described_class.new(
      name: name,
      description: description,
      parameters: parameters,
      &block
    )
  end

  describe "#initialize" do
    it "creates a function with the given attributes" do
      expect(function.name).to eq(name)
      expect(function.description).to eq(description)
      expect(function.parameters).to eq(parameters)
    end

    it "raises an error without a block" do
      expect {
        described_class.new(
          name: name,
          description: description,
          parameters: parameters
        )
      }.to raise_error(ArgumentError, "block is required")
    end
  end

  describe "#call" do
    it "calls the block with the given parameters" do
      result = function.call(param1: "test", param2: 123)
      expect(result).to eq({ result: ["test", 123, nil] })
    end

    it "accepts optional parameters" do
      result = function.call(param1: "test", param2: 123, param3: "optional")
      expect(result).to eq({ result: ["test", 123, "optional"] })
    end

    it "raises an error for missing required parameters" do
      expect {
        function.call(param1: "test")
      }.to raise_error(ArgumentError, /missing keyword: :param2/)
    end

    it "raises an error for invalid parameter types" do
      expect {
        function.call(param1: 123, param2: "invalid")
      }.to raise_error(TypeError, "param1 must be a String")
    end
  end

  describe "#to_openai_schema" do
    it "returns the function schema in OpenAI format" do
      schema = function.to_openai_schema
      expect(schema).to eq({
        name: name,
        description: description,
        parameters: {
          type: "object",
          properties: {
            param1: { type: "string" },
            param2: { type: "integer" },
            param3: { type: "string" }
          },
          required: [:param1, :param2]
        }
      })
    end

    it "handles complex type definitions" do
      function = described_class.new(
        name: name,
        description: description,
        parameters: {
          str: String,
          int: Integer,
          float: Float,
          bool: TrueClass,
          hash: Hash,
          complex: { type: String, optional: true },
          custom: Object
        }
      ) { |**kwargs| kwargs }

      schema = function.to_openai_schema
      expect(schema[:parameters][:properties]).to eq({
        str: { type: "string" },
        int: { type: "integer" },
        float: { type: "number" },
        bool: { type: "boolean" },
        hash: { type: "object" },
        complex: { type: "string" },
        custom: { type: "string" }
      })
      expect(schema[:parameters][:required]).to match_array([:str, :int, :float, :bool, :hash, :custom])
    end

    it "handles unknown array types" do
      function = described_class.new(
        name: name,
        description: description,
        parameters: {
          arr: [String, Integer],
          unknown: [Object, Class]
        }
      ) { |**kwargs| kwargs }

      schema = function.to_openai_schema
      expect(schema[:parameters][:properties]).to eq({
        arr: { type: "string" },
        unknown: { type: "string" }
      })
    end

    it "handles unknown types" do
      function = described_class.new(
        name: name,
        description: description,
        parameters: {
          unknown: Class,
          symbol: Symbol
        }
      ) { |**kwargs| kwargs }

      schema = function.to_openai_schema
      expect(schema[:parameters][:properties]).to eq({
        unknown: { type: "string" },
        symbol: { type: "string" }
      })
    end
  end
end
