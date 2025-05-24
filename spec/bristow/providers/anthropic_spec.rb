# frozen_string_literal: true

RSpec.describe Bristow::Providers::Anthropic do
  let(:provider) { described_class.new(api_key: "test-anthropic-key") }

  describe "#initialize" do
    it "creates an Anthropic client" do
      expect(provider.instance_variable_get(:@client)).to be_a(Anthropic::Client)
    end
  end

  describe "#default_model" do
    it "returns claude-3-5-sonnet-20241022" do
      expect(provider.default_model).to eq("claude-3-5-sonnet-20241022")
    end
  end

  describe "#format_functions" do
    let(:function_double) do
      double("function", to_schema: { name: "test_function", description: "Test" })
    end

    it "formats functions for Anthropic" do
      result = provider.format_functions([function_double])
      
      expect(result).to eq({
        tools: [{
          "name" => "test_function",
          "description" => "Test",
          "input_schema" => nil
        }]
      })
    end
  end

  describe "#chat" do
    it "calls Anthropic client and returns message" do
      mock_response = double("response")
      content_item = double("content", type: "text", text: "Hello!")
      allow(mock_response).to receive(:content).and_return([content_item])

      mock_client = instance_double(Anthropic::Client)
      mock_messages = instance_double("messages")
      allow(mock_client).to receive(:messages).and_return(mock_messages)
      allow(mock_messages).to receive(:create).with({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024,
        messages: []
      }).and_return(mock_response)
      
      provider.instance_variable_set(:@client, mock_client)
      
      result = provider.chat({ messages: [] })
      
      expect(result).to eq({
        "role" => "assistant",
        "content" => "Hello!"
      })
    end
  end
end