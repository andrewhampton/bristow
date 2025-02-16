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

    it "sends messages to OpenAI and streams the response" do
      chunks = [
        { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Hello" } }] },
        { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { content: "! I'm" } }] },
        { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { content: " here to help." } }] },
        { id: "4", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
      ]

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          },
          body: hash_including(
            messages: array_including(
              hash_including("role" => "user", "content" => "Hello")
            ),
            stream: true
          )
        )
        .to_return(
          status: 200,
          headers: {
            'Content-Type' => 'text/event-stream',
            'Transfer-Encoding' => 'chunked'
          },
          body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join)

      response = []
      agent.chat([{ role: "user", content: "Hello" }]) do |part|
        response << part
      end
      expect(response.join).to include("Hello")
    end

    it "accepts a string message" do
      chunks = [
        { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Hi" } }] },
        { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { content: " there" } }] },
        { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { content: "! How can I help?" } }] },
        { id: "4", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
      ]

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          },
          body: hash_including(
            messages: array_including(
              hash_including("role" => "user", "content" => "Hello")
            ),
            stream: true
          )
        )
        .to_return(
          status: 200,
          headers: {
            'Content-Type' => 'text/event-stream',
            'Transfer-Encoding' => 'chunked'
          },
          body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join)

      response = []
      agent.chat("Hello") do |part|
        response << part
      end
      expect(response.join).not_to be_empty
    end

    it "updates chat history" do
      chunks = [
        { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Test" } }] },
        { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { content: " response" } }] },
        { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
      ]

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          },
          body: hash_including(stream: true)
        )
        .to_return(
          status: 200,
          headers: {
            'Content-Type' => 'text/event-stream',
            'Transfer-Encoding' => 'chunked'
          },
          body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join)

      expect {
        agent.chat(messages, &block)
      }.to change { agent.chat_history.length }.by_at_least(1)
    end

    it "handles non-streaming responses" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          },
          body: hash_including(
            messages: array_including(
              hash_including("role" => "user", "content" => "Hello")
            )
          )
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            choices: [
              {
                message: {
                  role: "assistant",
                  content: "Hello! How can I help you?"
                }
              }
            ]
          }.to_json
        )

      response = agent.chat("Hello")
      expect(response).to include(
        a_hash_including(
          "role" => "assistant",
          "content" => "Hello! How can I help you?"
        )
      )
    end

    it "handles API errors" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer test_api_key'
          }
        )
        .to_return(
          status: 400,
          headers: { 'Content-Type' => 'application/json' },
          body: { error: { message: "Invalid request" } }.to_json
        )

      expect { agent.chat("Hello") }.to raise_error(Faraday::BadRequestError)
    end

    context "with function calls" do
      let(:messages) { [{ "role" => "user", "content" => "Please test the value 'example'" }] }

      it "raises error when function is not found" do
        chunks = [
          { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", function_call: { name: "nonexistent_function" } } }] },
          { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { function_call: { arguments: '{}' } } }] },
          { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "function_call" }] }
        ]

        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            }
          )
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'text/event-stream',
              'Transfer-Encoding' => 'chunked'
            },
            body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join
          )

        expect { agent.chat(messages, &block) }.to raise_error(ArgumentError, /Function nonexistent_function not found/)
      end

      it "handles function calls from the model" do
        # First request returns a function call
        function_call_chunks = [
          { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", function_call: { name: "test_function" } } }] },
          { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { function_call: { arguments: '{"param":' } } }] },
          { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { function_call: { arguments: '"example"}' } } }] },
          { id: "4", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "function_call" }] }
        ]

        # Second request returns a regular message
        final_response_chunks = [
          { id: "5", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Function call completed" } }] },
          { id: "6", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
        ]

        # Stub first request that returns function call
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            },
            body: hash_including(
              messages: array_including(
                hash_including("role" => "user", "content" => "Please test the value 'example'")
              ),
              stream: true
            )
          )
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'text/event-stream',
              'Transfer-Encoding' => 'chunked'
            },
            body: function_call_chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join
          )

        # Stub second request that returns final response
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            },
            body: hash_including(
              messages: array_including(
                hash_including("role" => "function", "name" => "test_function")
              ),
              stream: true
            )
          )
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'text/event-stream',
              'Transfer-Encoding' => 'chunked'
            },
            body: final_response_chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join
          )

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

      it "handles empty deltas in streaming" do
        chunks = [
          { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {} }] },
          { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Hello" } }] },
          { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
        ]

        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            }
          )
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'text/event-stream',
              'Transfer-Encoding' => 'chunked'
            },
            body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join
          )

        response = []
        agent.chat(messages) { |part| response << part }
        expect(response.join).to eq("Hello")
      end

      it "handles missing choices in streaming" do
        chunks = [
          { id: "1", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo" },
          { id: "2", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: { role: "assistant", content: "Hello" } }] },
          { id: "3", object: "chat.completion.chunk", created: Time.now.to_i, model: "gpt-3.5-turbo", choices: [{ index: 0, delta: {}, finish_reason: "stop" }] }
        ]

        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            }
          )
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'text/event-stream',
              'Transfer-Encoding' => 'chunked'
            },
            body: chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join
          )

        response = []
        agent.chat(messages) { |part| response << part }
        expect(response.join).to eq("Hello")
      end
    end
  end
end
