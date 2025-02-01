# frozen_string_literal: true

RSpec.describe Bristow::Agent do
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

      def perform(param:)
        { result: param }
      end
    end
  end

  let(:test_agent) do
    test_function = @test_function
    Class.new(described_class) do
      name "TestAgent"
      description "A test agent"
      system_message "You are a test agent that helps with testing. When asked to test something, always use the test_function."
      model "gpt-3.5-turbo"
      functions [test_function]
    end
  end

  subject(:agent) { test_agent.new }

  describe ".name" do
    it "sets and gets the agent name" do
      expect(test_agent.name).to eq("TestAgent")
    end
  end

  describe ".description" do
    it "sets and gets the agent description" do
      expect(test_agent.description).to eq("A test agent")
    end
  end

  describe ".system_message" do
    it "sets and gets the system message" do
      expect(test_agent.system_message).to include("You are a test agent")
    end
  end

  describe ".model" do
    it "sets and gets the model" do
      expect(test_agent.model).to eq("gpt-3.5-turbo")
    end

    it "defaults to configuration default model" do
      agent_class = Class.new(described_class) do
        name "DefaultModelAgent"
      end
      expect(agent_class.model).to eq(Bristow.configuration.model)
    end
  end

  describe ".functions" do
    it "sets and gets the functions" do
      expect(test_agent.functions).to eq([@test_function])
    end

    it "defaults to empty array" do
      agent_class = Class.new(described_class) do
        name "NoFunctionsAgent"
      end
      expect(agent_class.functions).to eq([])
    end
  end

  describe "#chat" do
    let(:messages) { [{ "role" => "user", "content" => "Hello" }] }
    let(:block) { proc { |part| @streamed_parts ||= []; @streamed_parts << part } }

    before do
      @streamed_parts = []
    end

    it "sends messages to OpenAI and streams the response", vcr: { cassette_name: "Bristow_Agent_chat_sends_messages_to_OpenAI_and_streams_the_response" } do
      response = []
      agent.chat([{ role: "user", content: "Hello" }]) do |part|
        response << part
      end
      expect(response.join).to include("Hello")
    end

    it "accepts a string message", vcr: { cassette_name: "Bristow_Agent_chat_accepts_string_message" } do
      response = []
      agent.chat("Hello") do |part|
        response << part
      end
      expect(response.join).not_to be_empty
    end

    it "updates chat history", vcr: true do
      expect {
        agent.chat(messages, &block)
      }.to change { agent.chat_history.length }.by_at_least(1)
    end

    context "with function calls" do
      let(:messages) { [{ "role" => "user", "content" => "Please test the value 'example'" }] }

      it "handles function calls from the model", vcr: true do
        response = agent.chat(messages, &block)
        expect(response).to include(
          a_hash_including(
            "role" => "assistant",
            "function_call" => a_hash_including(
              "name" => "test_function",
              "arguments" => a_string_matching(/example/)
            )
          )
        )
      end
    end
  end
end
