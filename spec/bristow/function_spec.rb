# frozen_string_literal: true

RSpec.describe Bristow::Function do
  let(:name) { "test_function" }
  let(:description) { "A test function" }
  let(:parameters) do
    {
      properties: {
        param1: {
          type: "string",
          description: "First parameter"
        },
        param2: {
          type: "integer",
          description: "Second parameter"
        },
        param3: {
          type: "string",
          description: "Optional third parameter"
        }
      },
      required: ["param1", "param2"]
    }
  end
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
      }.to raise_error(ArgumentError, /missing keyword: param2/)
    end
  end

  describe "#to_openai_schema" do
    it "returns the correct schema format" do
      schema = function.to_openai_schema
      expect(schema).to eq({
        name: name,
        description: description,
        parameters: parameters
      })
    end
  end
end
