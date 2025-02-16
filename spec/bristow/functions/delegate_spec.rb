require "spec_helper"

RSpec.describe Bristow::Functions::Delegate do
  let(:test_agent) do
    Class.new(Bristow::Agent) do
      name "TestAgent"
      description "A test agent"
      system_message "You are a test agent"
    end.new
  end

  let(:test_agency) do
    test_agent_instance = test_agent
    Class.new(Bristow::Agency) do
      define_method(:find_agent) do |name|
        return nil if name == "NonexistentAgent"
        test_agent_instance
      end
    end.new
  end

  subject(:delegate) { described_class.new(test_agent, test_agency) }

  describe "#initialize" do
    it "raises error when agent is nil" do
      expect { described_class.new(nil, test_agency) }.to raise_error(ArgumentError, "Agent must not be nil")
    end

    it "initializes with valid agent and agency" do
      expect { described_class.new(test_agent, test_agency) }.not_to raise_error
    end
  end

  describe "#perform" do
    it "raises error when agency is nil" do
      delegate.agency = nil
      expect { delegate.perform(agent_name: "OtherAgent", message: "Hello") }.to raise_error("Agency not set")
    end

    it "returns error when delegating to self" do
      result = delegate.perform(agent_name: "TestAgent", message: "Hello")
      expect(result).to eq(error: "Cannot delegate to self")
    end

    it "raises error when agent not found" do
      expect { delegate.perform(agent_name: "NonexistentAgent", message: "Hello") }
        .to raise_error(ArgumentError, "Agent NonexistentAgent not found")
    end

    it "delegates message to another agent" do
      allow(test_agent).to receive(:chat).and_return([{ "role" => "assistant", "content" => "Response" }])
      result = delegate.perform(agent_name: "OtherAgent", message: "Hello")
      expect(result).to eq(response: "Response")
    end

    it "handles nil response from agent" do
      allow(test_agent).to receive(:chat).and_return(nil)
      result = delegate.perform(agent_name: "OtherAgent", message: "Hello")
      expect(result).to eq(response: nil)
    end

    it "handles empty response from agent" do
      allow(test_agent).to receive(:chat).and_return([])
      result = delegate.perform(agent_name: "OtherAgent", message: "Hello")
      expect(result).to eq(response: nil)
    end
  end

  describe "class methods" do
    it "has correct name" do
      expect(described_class.name).to eq("delegate_to")
    end

    it "has description" do
      expect(described_class.description).to be_a(String)
    end

    it "has valid parameters schema" do
      params = described_class.parameters
      expect(params[:type]).to eq("object")
      expect(params[:properties]).to include(:agent_name, :message)
      expect(params[:required]).to eq(["agent_name", "message"])
    end
  end
end
