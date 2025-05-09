# frozen_string_literal: true

RSpec.describe Bristow::Agencies::Workflow do
  let(:test_agent_one) do
    Class.new(Bristow::Agent) do
      agent_name "TestAgentOne"
      description "A test agent that modifies messages"
      system_message "You are test agent one"

      def self.chat(messages, &block)
        messages + [{ role: "assistant", content: "Agent One Response" }]
      end
    end
  end

  let(:test_agent_two) do
    Class.new(Bristow::Agent) do
      agent_name "TestAgentTwo"
      description "A test agent that processes messages"
      system_message "You are test agent two"

      def self.chat(messages, &block)
        yield "Agent Two Response" if block
        messages + [{ role: "assistant", content: "Agent Two Response" }]
      end
    end
  end

  let(:test_workflow) do
    agent_one = test_agent_one
    agent_two = test_agent_two
    Class.new(described_class) do
      agents [agent_one, agent_two]
    end
  end

  subject(:workflow) { test_workflow.new }

  describe "#chat" do
    let(:messages) { [{ role: "user", content: "Hello" }] }
    let(:block) { proc { |part| @streamed_parts << part } }

    before do
      @streamed_parts = []
    end

    it "returns original messages if no agents" do
      workflow = described_class.new(agents: [])
      expect(workflow.chat(messages)).to eq(messages)
    end

    it "processes messages through all agents" do
      result = workflow.chat(messages, &block)
      expect(result).to eq([
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Agent One Response" },
        { role: "assistant", content: "Agent Two Response" }
      ])
    end

    it "only streams output from the last agent" do
      workflow.chat(messages, &block)
      expect(@streamed_parts).to eq(["Agent Two Response"])
    end

    it "handles agents that don't accept blocks" do
      workflow = described_class.new(agents: [test_agent_one.new])
      
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          }
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            choices: [
              {
                message: {
                  role: "assistant",
                  content: "Response"
                }
              }
            ]
          }.to_json
        )

      expect { workflow.chat(messages, &block) }.not_to raise_error
    end

    it "processes messages through all agents in sequence" do
      result = workflow.chat(messages, &block)
      expect(result).to eq([
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Agent One Response" },
        { role: "assistant", content: "Agent Two Response" }
      ])
    end

    it "only streams output from the last agent" do
      workflow.chat(messages, &block)
      expect(@streamed_parts).to eq(["Agent Two Response"])
    end

    it "accepts a string message" do
      result = workflow.chat([{role: 'user', content: "Hello"}], &block)
      expect(result.first).to eq({ role: "user", content: "Hello" })
    end

    it "works without a block" do
      expect {
        workflow.chat(messages)
      }.not_to raise_error
    end

    context "with multiple agents" do
      let(:test_workflow_three) do
        agent_one = test_agent_one
        agent_two = test_agent_two
        agent_three = Class.new(test_agent_two) do
          agent_name "TestAgentThree"
          def self.chat(messages, &block)
            yield "Agent Three Response" if block
            messages + [{ role: "assistant", content: "Agent Three Response" }]
          end
        end

        Class.new(described_class) do
          agents [agent_one, agent_two, agent_three]
        end
      end

      it "processes through all agents and only streams the last one" do
        workflow = test_workflow_three.new
        workflow.chat(messages, &block)
        expect(@streamed_parts).to eq(["Agent Three Response"])
      end
    end
  end
end
