# frozen_string_literal: true

RSpec.describe Bristow::Agencies::Supervisor do
  let(:test_agent_one) do
    Class.new(Bristow::Agent) do
      name "TestAgentOne"
      description "A test agent that modifies messages"
      system_message "You are test agent one"
    end
  end

  let(:test_agent_two) do
    Class.new(Bristow::Agent) do
      name "TestAgentTwo"
      description "A test agent that processes messages"
      system_message "You are test agent two"
    end
  end

  let(:custom_instructions) { "Custom supervisor instructions" }

  subject(:supervisor) { described_class.new(custom_instructions: custom_instructions, agents: [test_agent_one.new, test_agent_two.new]) }

  describe "#initialize" do
    it "sets custom instructions" do
      expect(supervisor.custom_instructions).to eq("Custom supervisor instructions")
    end

    it "initializes with agents" do
      expect(supervisor.agents).to include(test_agent_one, test_agent_two)
    end
  end

  describe "#chat" do
    let(:messages) { [{ role: "user", content: "Hello" }] }
    let(:block) { proc { |part| @streamed_parts << part } }

    before do
      @streamed_parts = []
    end

    it "raises error if supervisor not set" do
      supervisor.instance_variable_set(:@supervisor, nil)
      expect { supervisor.chat(messages) }.to raise_error("Supervisor not set")
    end

    it "formats string message to proper format" do
      allow(supervisor.supervisor).to receive(:chat).and_return([{ role: "assistant", content: "Response" }])
      supervisor.chat("Hello")
      expect(supervisor.supervisor).to have_received(:chat).with([{ role: "user", content: "Hello" }])
    end

    it "delegates chat to supervisor agent" do
      allow(supervisor.supervisor).to receive(:chat).and_return([{ role: "assistant", content: "Response" }])
      result = supervisor.chat(messages, &block)
      expect(result).to eq([{ role: "assistant", content: "Response" }])
    end
  end
  before(:all) do
    @test_function = Class.new(Bristow::Function) do
      name "test_function"
      description "A test function"
      parameters({
        type: "object",
        properties: {
          param: {
            type: "string",
            description: "A test parameter"
          }
        },
        required: ["param"]
      })

      def self.perform(param:)
        { result: param }
      end
    end

    @test_agent_class = Class.new(Bristow::Agent) do
      name "TestAgent"
      description "A test agent"
      system_message "You are a test agent"
      functions [@test_function]
    end
  end

  let(:test_agency) do
    test_agent_class = @test_agent_class
    Class.new(described_class) do
      agents [test_agent_class]
    end
  end

  subject(:agency) { test_agency.new }

  describe ".create" do
    it "creates an agency with the given agents" do
      expect(test_agency.agents).to eq([@test_agent_class])
    end

    it "creates and sets up a supervisor" do
      expect(agency.supervisor).to be_a(Bristow::Agents::Supervisor)
    end
  end

  describe "#chat" do
    let(:messages) { [{ role: "user", content: "Hello" }] }
    let(:block) { proc { |part| @streamed_parts << part } }

    before do
      @streamed_parts = []
    end

    it "delegates chat to supervisor" do
      expect(agency.supervisor).to receive(:chat).with(messages, &block)
      agency.chat(messages, &block)
    end

    it "delegates chat to supervisor" do
      expect(agency.supervisor).to receive(:chat).with(messages, &block)
      agency.chat(messages, &block)
    end

    it "accepts a string message" do
      expect(agency.supervisor).to receive(:chat).with([{ role: "user", content: "Hello" }], &block)
      agency.chat("Hello", &block)
    end

    it "raises error when supervisor not set" do
      agency.instance_variable_set(:@supervisor, nil)
      expect {
        agency.chat(messages, &block)
      }.to raise_error(RuntimeError, /Supervisor not set/)
    end

    it "handles array and non-array messages" do
      expect(agency.supervisor).to receive(:chat).with([{ role: "user", content: "Hello" }], &block)
      agency.chat("Hello", &block)

      expect(agency.supervisor).to receive(:chat).with(messages, &block)
      agency.chat(messages, &block)
    end
  end

  describe "delegation" do
    let(:delegate_fn) { agency.supervisor.functions.find { |f| f.name == "delegate_to" } }

    it "delegates to the specified agent" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            id: "chatcmpl-123",
            object: "chat.completion",
            created: Time.now.to_i,
            model: "gpt-3.5-turbo-0613",
            choices: [
              {
                index: 0,
                message: {
                  role: "assistant",
                  content: "Hello! How can I assist you today?"
                },
                finish_reason: "stop"
              }
            ],
            usage: {
              prompt_tokens: 9,
              completion_tokens: 12,
              total_tokens: 21
            }
          }.to_json
        )

      response = delegate_fn.call(
        agent_name: "TestAgent",
        message: "Hello"
      )
      expect(response).to match(response: "Hello! How can I assist you today?")
    end

    it "raises error when agency not set" do
      delegate_fn.instance_variable_set(:@agency, nil)
      expect {
        delegate_fn.call(
          agent_name: "TestAgent",
          message: "Hello"
        )
      }.to raise_error(RuntimeError, /Agency not set/)
    end

    it "raises error when agent not found" do
      expect {
        delegate_fn.call(
          agent_name: "UnknownBot",
          message: "Hello"
        )
      }.to raise_error(ArgumentError, /Agent UnknownBot not found/)
    end

    it "prevents self-delegation" do
      result = delegate_fn.call(
        agent_name: "Supervisor",
        message: "Hello"
      )

      expect(result).to match(error: "Cannot delegate to self")
    end
  end
end
