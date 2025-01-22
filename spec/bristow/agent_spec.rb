# frozen_string_literal: true

RSpec.describe Bristow::Agent do
  let(:name) { "TestAgent" }
  let(:description) { "A test agent" }
  let(:system_message) { "You are a test agent that helps with testing. When asked to test something, always use the test_function." }
  let(:model) { "gpt-3.5-turbo" }
  let(:function) do
    Bristow::Function.new(
      name: "test_function",
      description: "A test function",
      parameters: { param: String }
    ) { |param:| { result: param } }
  end

  subject(:agent) do
    described_class.new(
      name: name,
      description: description,
      system_message: system_message,
      functions: [function],
      model: model
    )
  end

  describe "#initialize" do
    it "creates an agent with the given attributes" do
      expect(agent.name).to eq(name)
      expect(agent.description).to eq(description)
      expect(agent.chat_history).to be_empty
    end

    it "defaults functions to empty array" do
      agent = described_class.new(
        name: name,
        description: description
      )
      expect(agent.functions).to be_empty
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

    it "accepts an array of string messages", vcr: true do
      response = []
      agent.chat(["Hello", "How are you?"]) do |part|
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
