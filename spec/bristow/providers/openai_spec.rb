# frozen_string_literal: true

RSpec.describe Bristow::Providers::Openai do
  let(:provider) { described_class.new(api_key: "test-openai-key") }

  describe "#initialize" do
    it "creates an OpenAI client" do
      expect(provider.instance_variable_get(:@client)).to be_a(OpenAI::Client)
    end
  end

  describe "#default_model" do
    it "returns gpt-4o-mini" do
      expect(provider.default_model).to eq("gpt-4o-mini")
    end
  end

  describe "#format_functions" do
    let(:function_double) do
      double("function", to_schema: { name: "test_function", description: "Test" })
    end

    it "formats functions for OpenAI" do
      result = provider.format_functions([function_double])
      
      expect(result).to eq({
        functions: [{ name: "test_function", description: "Test" }],
        function_call: "auto"
      })
    end
  end

  describe "#chat" do
    it "calls OpenAI client and returns message" do
      mock_response = {
        "choices" => [
          {
            "message" => {
              "role" => "assistant", 
              "content" => "Hello!"
            }
          }
        ]
      }

      mock_client = instance_double(OpenAI::Client)
      allow(mock_client).to receive(:chat).with(parameters: { model: "gpt-4o-mini", messages: [] })
                                          .and_return(mock_response)
      
      provider.instance_variable_set(:@client, mock_client)
      
      result = provider.chat({ model: "gpt-4o-mini", messages: [] })
      
      expect(result).to eq({
        "role" => "assistant",
        "content" => "Hello!"
      })
    end
  end

  describe "#stream_chat" do
    it "handles streaming with content" do
      mock_client = instance_double(OpenAI::Client)
      
      # Mock the streaming behavior
      allow(mock_client).to receive(:chat) do |args|
        stream_proc = args[:parameters][:stream]
        
        # Simulate streaming chunks
        stream_proc.call({
          "choices" => [
            {
              "delta" => {
                "role" => "assistant",
                "content" => "Hello"
              }
            }
          ]
        })
        
        stream_proc.call({
          "choices" => [
            {
              "delta" => {
                "content" => " world!"
              }
            }
          ]
        })
      end
      
      provider.instance_variable_set(:@client, mock_client)
      
      yielded_content = []
      result = provider.stream_chat({ model: "gpt-4o-mini", messages: [] }) do |content|
        yielded_content << content
      end
      
      expect(yielded_content).to eq(["Hello", " world!"])
      expect(result).to eq({
        "role" => "assistant",
        "content" => "Hello world!"
      })
    end

    it "handles streaming with function calls" do
      mock_client = instance_double(OpenAI::Client)
      
      allow(mock_client).to receive(:chat) do |args|
        stream_proc = args[:parameters][:stream]
        
        # Simulate function call chunks
        stream_proc.call({
          "choices" => [
            {
              "delta" => {
                "role" => "assistant",
                "function_call" => {
                  "name" => "test_function"
                }
              }
            }
          ]
        })
        
        stream_proc.call({
          "choices" => [
            {
              "delta" => {
                "function_call" => {
                  "arguments" => '{"param":'
                }
              }
            }
          ]
        })
        
        stream_proc.call({
          "choices" => [
            {
              "delta" => {
                "function_call" => {
                  "arguments" => '"value"}'
                }
              }
            }
          ]
        })
      end
      
      provider.instance_variable_set(:@client, mock_client)
      
      result = provider.stream_chat({ model: "gpt-4o-mini", messages: [] })
      
      expect(result).to eq({
        "role" => "assistant",
        "function_call" => {
          "name" => "test_function",
          "arguments" => '{"param":"value"}'
        }
      })
    end
  end
end