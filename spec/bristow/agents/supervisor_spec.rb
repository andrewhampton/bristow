# frozen_string_literal: true
RSpec.describe Bristow::Agents::Supervisor do
  before(:all) do
    @test_agent_class = Class.new(Bristow::Agent) do
      agent_name "TestAgent"
      description "A test agent"
      system_message "You are a test agent"
    end
  end

  let(:agency) { Bristow::Agency.new }
  let(:test_agent) { @test_agent_class.new }
  let(:child_agents) { [test_agent] }
  let(:custom_instructions) { "Custom supervisor instructions" }
  subject(:supervisor) { described_class.new(child_agents: child_agents, agency: agency, custom_instructions: custom_instructions) }

  before do
    # Add test agent to agency
    agency.agents << test_agent
  end

  describe ".class_methods" do
    it "has correct class-level attributes" do
      expect(described_class.agent_name).to eq("Supervisor")
      expect(described_class.description).to eq("A supervisor agent that coordinates between specialized agents")
      expect(described_class.custom_instructions).to be_nil
    end

    it "allows setting class-level custom instructions" do
      old_instructions = described_class.custom_instructions
      described_class.custom_instructions("Default instructions")
      expect(described_class.custom_instructions).to eq("Default instructions")
      described_class.custom_instructions(old_instructions)
    end
  end

  describe "#initialize" do
    it "creates a supervisor with available agents" do
      expect(supervisor.agent_name).to eq("Supervisor")
      expect(described_class.description).to eq("A supervisor agent that coordinates between specialized agents")
    end

    it "includes agent descriptions in system message" do
      expect(supervisor.system_message).to match(/Available agents:\n- TestAgent: A test agent\n/)
    end

    it "includes custom instructions in system message" do
      expect(supervisor.system_message).to include(custom_instructions)
    end

    it "uses class-level custom instructions when none provided" do
      old_instructions = described_class.custom_instructions
      described_class.custom_instructions("Default instructions")
      supervisor_without_instructions = described_class.new(child_agents: child_agents, agency: agency)
      expect(supervisor_without_instructions.system_message).to include("Default instructions")
      described_class.custom_instructions(old_instructions)
    end

    it "sets up delegation function" do
      delegate_fn = supervisor.functions.first
      expect(delegate_fn.function_name).to eq("delegate_to")
      expect(delegate_fn.parameters[:properties]).to include(:agent_name, :message)
    end

    it "adds itself to the agency" do
      expect(agency.agents).to include(supervisor)
    end
  end

  describe "#chat" do
    let(:client) { instance_double(OpenAI::Client) }
    let(:messages) { [{ role: "user", content: "Please help me" }] }
    let(:function_call_response) do
      {
        "role" => "assistant",
        "function_call" => {
          "name" => "delegate_to",
          "arguments" => JSON.dump({
            "agent_name" => "TestAgent",
            "message" => "How can I help you?"
          })
        }
      }
    end
    let(:final_response) do
      {
        "role" => "assistant",
        "content" => "I've helped you with that"
      }
    end

    before do
      # Mock the provider instead of the client directly
      mock_provider = instance_double(Bristow::Providers::Openai)
      allow(Bristow.configuration).to receive(:client_for).with(:openai).and_return(mock_provider)
      allow(Bristow.configuration).to receive(:client).and_return(mock_provider)
      allow(mock_provider).to receive(:default_model).and_return("gpt-4o-mini")
      allow(mock_provider).to receive(:format_functions).and_return({
        functions: [{ name: "delegate_to", description: "Delegate a task to a specialized agent" }],
        function_call: "auto"
      })
      allow(mock_provider).to receive(:chat).and_return(function_call_response, final_response)
      allow(mock_provider).to receive(:is_function_call?) do |response|
        response.key?("function_call")
      end
      allow(mock_provider).to receive(:function_name) do |response|
        response["function_call"]["name"]
      end
      allow(mock_provider).to receive(:function_arguments) do |response|
        JSON.parse(response["function_call"]["arguments"])
      end
      allow(mock_provider).to receive(:format_function_response) do |response, result|
        {
          "role" => "function",
          "name" => response["function_call"]["name"],
          "content" => result.to_json
        }
      end
      allow(test_agent).to receive(:chat).and_return([{ "role" => "assistant", "content" => "Test response" }])
    end

    it "accepts string messages" do
      messages = supervisor.chat("Help me")
      expect(messages).to include(
        hash_including("role" => "assistant", "content" => "I've helped you with that")
      )
    end

    it "handles API errors" do
      # Reset the mock to only return the error
      mock_provider = instance_double(Bristow::Providers::Openai)
      allow(Bristow.configuration).to receive(:client_for).with(:openai).and_return(mock_provider)
      allow(Bristow.configuration).to receive(:client).and_return(mock_provider)
      allow(mock_provider).to receive(:default_model).and_return("gpt-4o-mini")
      allow(mock_provider).to receive(:format_functions).and_return({
        functions: [{ name: "delegate_to", description: "Delegate a task to a specialized agent" }],
        function_call: "auto"
      })
      allow(mock_provider).to receive(:chat).and_raise(Faraday::BadRequestError.new(nil, { body: "error" }))
      
      expect {
        supervisor.chat("Help me")
      }.to raise_error(Faraday::BadRequestError)
    end
  end

  describe "delegation" do
    let(:delegate_fn) { supervisor.functions.first }

    before do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}"
          }
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            choices: [{
              message: {
                role: "assistant",
                content: "Test response"
              }
            }]
          }.to_json
        )

      allow(test_agent).to receive(:chat).and_return([{ "role" => "assistant", "content" => "Test response" }])
    end

    it "delegates to the specified agent" do
      response = delegate_fn.call(
        agent_name: "TestAgent",
        message: "Hello"
      )
      expect(response).to match(response: "Test response")
    end

    it "raises error when agency not set" do
      delegate_fn.agency = nil
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

    it "handles empty response from agent" do
      allow(test_agent).to receive(:chat).and_return([])
      response = delegate_fn.call(
        agent_name: "TestAgent",
        message: "Hello"
      )
      expect(response).to match(response: nil)
    end

    it "handles nil content in response" do
      allow(test_agent).to receive(:chat).and_return([{ "role" => "assistant", "content" => nil }])
      response = delegate_fn.call(
        agent_name: "TestAgent",
        message: "Hello"
      )
      expect(response).to match(response: nil)
    end
  end

  describe "delegate function" do
    let(:agency) { Bristow::Agency.new }
    let(:supervisor) { described_class.new(child_agents: [], agency: agency) }

    it "raises error when initialized with nil agent" do
      expect {
        Bristow::Functions::Delegate.new(nil, agency)
      }.to raise_error(ArgumentError, /Agent must not be nil/)
    end

    it "has correct class-level attributes" do
      delegate_class = Bristow::Functions::Delegate
      expect(delegate_class.function_name).to eq("delegate_to")
      expect(delegate_class.description).to eq("Delegate a task to a specialized agent")
      expect(delegate_class.parameters).to include(
        type: "object",
        properties: hash_including(
          agent_name: hash_including(type: "string"),
          message: hash_including(type: "string")
        ),
        required: ["agent_name", "message"]
      )
    end

    it "delegates class methods to instance methods" do
      delegate = Bristow::Functions::Delegate.new(supervisor, agency)
      expect(delegate.function_name).to eq(Bristow::Functions::Delegate.function_name)
      expect(delegate.description).to eq(Bristow::Functions::Delegate.description)
      expect(delegate.parameters).to eq(Bristow::Functions::Delegate.parameters)
    end
  end
end
