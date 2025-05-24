# frozen_string_literal: true

RSpec.describe Bristow::Function do
  let(:test_function_class) do
    Class.new(described_class) do
      function_name "test_function"
      description "A test function"
      parameters({
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
      })

      def perform(param1:, param2:, param3: nil)
        { result: [param1, param2, param3] }
      end
    end
  end

  subject(:function) { test_function_class.new }

  describe ".function_name" do
    it "sets and gets the function name" do
      expect(test_function_class.function_name).to eq("test_function")
    end
  end

  describe ".description" do
    it "sets and gets the function description" do
      expect(test_function_class.description).to eq("A test function")
    end
  end

  describe ".parameters" do
    it "sets and gets the function parameters" do
      expect(test_function_class.parameters[:properties]).to include(:param1, :param2, :param3)
      expect(test_function_class.parameters[:required]).to eq(["param1", "param2"])
    end
  end

  describe "#call" do
    it "calls perform with the given parameters" do
      result = function.call(param1: "test", param2: 123)
      expect(result).to eq({ result: ["test", 123, nil] })
    end

    it "accepts optional parameters" do
      result = function.call(param1: "test", param2: 123, param3: "optional")
      expect(result).to eq({ result: ["test", 123, "optional"] })
    end

    it "raises an error for missing required parameters" do
      result =  function.call(param1: "test")
      expect(result).to eq("missing parameters: [:param2]")
    end
  end

  describe "#perform" do
    it "raises NotImplementedError in the base class" do
      expect {
        described_class.new.perform
      }.to raise_error(NotImplementedError, /must be implemented/)
    end
  end

  describe "#to_schema" do
    it "returns the correct schema format" do
      schema = function.to_schema
      expect(schema).to eq({
        name: "test_function",
        description: "A test function",
        parameters: test_function_class.parameters
      })
    end
  end
end
