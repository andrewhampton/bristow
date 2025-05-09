# frozen_string_literal: true

RSpec.describe Bristow::Agency do
  before(:all) do
    @test_agent1_class = Class.new(Bristow::Agent) do
      agent_name "TestAgent1"
      description "A test agent"
    end

    @test_agent2_class = Class.new(Bristow::Agent) do
      agent_name "TestAgent2"
      description "Another test agent"
    end
  end

  let(:test_agency) do
    test_agent1_class = @test_agent1_class
    test_agent2_class = @test_agent2_class
    test_agent3 = @test_agent1_class.new
    Class.new(described_class) do
      agents [test_agent1_class, test_agent2_class, test_agent3]
    end
  end

  subject(:agency) { test_agency.new }

  describe ".agents" do
    it "sets and gets the agents" do
      agents = test_agency.agents
      expect(agents.length).to eq(3)
      expect(agents[0]).to eq(@test_agent1_class)
      expect(agents[1]).to eq(@test_agent2_class)
      expect(agents[2]).to be_a(@test_agent1_class)
    end

    it "defaults to empty array" do
      agency_class = Class.new(described_class)
      expect(agency_class.agents).to eq([])
    end
  end

  describe "#find_agent" do
    it "finds an agent by agent_name from a class" do
      expect(agency.find_agent("TestAgent1")).to be_a(@test_agent1_class)
    end

    it "finds an agent by agent_name from an instance" do
      expect(agency.find_agent("TestAgent1")).to be_a(@test_agent1_class)
    end

    it "returns nil for unknown agent" do
      expect(agency.find_agent("UnknownAgent")).to be_nil
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
    it "calls the agent with messages and block" do
      messages = [{ role: "user", content: "Hello" }]
      block = proc { |part| @streamed_parts << part }
      @streamed_parts = []

      agent = agency.find_agent("TestAgent1")
      expect(agent).to receive(:chat).with(messages, &block)

      agency.send(:call_agent, agent, messages, &block)
    end
  end
end
