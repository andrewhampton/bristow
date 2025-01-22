# frozen_string_literal: true

RSpec.describe Bristow::Agency do
  let(:agent1) do
    Bristow::Agent.new(
      name: "Agent1",
      description: "First test agent"
    )
  end

  let(:agent2) do
    Bristow::Agent.new(
      name: "Agent2",
      description: "Second test agent"
    )
  end

  subject(:agency) do
    described_class.new(agents: [agent1, agent2])
  end

  describe "#initialize" do
    it "creates an agency with the given agents" do
      expect(agency.agents).to contain_exactly(agent1, agent2)
    end

    it "defaults to empty agents array" do
      agency = described_class.new
      expect(agency.agents).to be_empty
    end
  end

  describe "#find_agent" do
    it "finds an agent by name" do
      expect(agency.find_agent("Agent1")).to eq(agent1)
      expect(agency.find_agent("Agent2")).to eq(agent2)
    end

    it "returns nil for unknown agent" do
      expect(agency.find_agent("Unknown")).to be_nil
    end
  end

  describe "#chat" do
    it "raises NotImplementedError" do
      expect {
        agency.chat("test")
      }.to raise_error(NotImplementedError, /must be implemented/)
    end
  end

  describe "#call_agent" do
    let(:messages) { [{ "role" => "user", "content" => "test" }] }
    let(:block) { proc { |part| @streamed_parts ||= []; @streamed_parts << part } }

    it "calls the agent with messages and block", :vcr do
      expect(agent1).to receive(:chat).with(messages, &block)
      agency.send(:call_agent, agent1, messages, &block)
    end
  end
end
