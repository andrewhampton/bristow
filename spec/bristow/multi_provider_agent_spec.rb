# frozen_string_literal: true

RSpec.describe "Multi-Provider Agent Support" do
  before do
    # Reset configuration for each test
    Bristow.reset_configuration!
    
    Bristow.configure do |config|
      config.openai_api_key = "test-openai-key"
      config.anthropic_api_key = "test-anthropic-key"
      config.google_api_key = "test-google-key"
      config.default_provider = :openai
      config.logger = Logger.new(File::NULL)
    end
  end

  describe "Agent provider configuration" do
    let(:openai_agent_class) do
      Class.new(Bristow::Agent) do
        agent_name "OpenAI Agent"
        provider :openai
        model "gpt-4o"
        system_message "You are an OpenAI agent"
      end
    end

    let(:anthropic_agent_class) do
      Class.new(Bristow::Agent) do
        agent_name "Anthropic Agent"
        provider :anthropic
        model "claude-3-opus-20240229"
        system_message "You are an Anthropic agent"
      end
    end

    let(:google_agent_class) do
      Class.new(Bristow::Agent) do
        agent_name "Google Agent"
        provider :google
        model "gemini-pro"
        system_message "You are a Google agent"
      end
    end

    let(:default_agent_class) do
      Class.new(Bristow::Agent) do
        agent_name "Default Agent"
        system_message "You are a default agent"
      end
    end

    describe "class-level provider configuration" do
      it "configures OpenAI provider" do
        expect(openai_agent_class.provider).to eq(:openai)
        expect(openai_agent_class.model).to eq("gpt-4o")
      end

      it "configures Anthropic provider" do
        expect(anthropic_agent_class.provider).to eq(:anthropic)
        expect(anthropic_agent_class.model).to eq("claude-3-opus-20240229")
      end

      it "configures Google provider" do
        expect(google_agent_class.provider).to eq(:google)
        expect(google_agent_class.model).to eq("gemini-pro")
      end

      it "defaults to configuration default provider" do
        expect(default_agent_class.provider).to eq(:openai)
      end
    end

    describe "instance-level provider configuration" do
      it "creates OpenAI agent instance" do
        agent = openai_agent_class.new

        expect(agent.provider).to eq(:openai)
        expect(agent.model).to eq("gpt-4o")
        expect(agent.client).to be_a(Bristow::Providers::Openai)
      end

      it "creates Anthropic agent instance" do
        agent = anthropic_agent_class.new

        expect(agent.provider).to eq(:anthropic)
        expect(agent.model).to eq("claude-3-opus-20240229")
        expect(agent.client).to be_a(Bristow::Providers::Anthropic)
      end

      it "creates Google agent instance" do
        agent = google_agent_class.new

        expect(agent.provider).to eq(:google)
        expect(agent.model).to eq("gemini-pro")
        expect(agent.client).to be_a(Bristow::Providers::Google)
      end

      it "creates default agent instance" do
        agent = default_agent_class.new

        expect(agent.provider).to eq(:openai)
        expect(agent.client).to be_a(Bristow::Providers::Openai)
      end
    end

    describe "dynamic provider override" do
      it "overrides provider at instantiation" do
        agent = openai_agent_class.new(provider: :anthropic, model: "claude-3-haiku-20240307")

        expect(agent.provider).to eq(:anthropic)
        expect(agent.model).to eq("claude-3-haiku-20240307")
        expect(agent.client).to be_a(Bristow::Providers::Anthropic)
      end

      it "overrides only provider, keeping class model" do
        agent = openai_agent_class.new(provider: :google)

        expect(agent.provider).to eq(:google)
        expect(agent.model).to eq("gpt-4o") # Keeps class-defined model
        expect(agent.client).to be_a(Bristow::Providers::Google)
      end

      it "can override to use custom client" do
        custom_client = double("custom_client")
        agent = openai_agent_class.new(client: custom_client)

        expect(agent.client).to be(custom_client)
      end
    end
  end

  describe "formatted_functions method" do
    let(:test_function) do
      Class.new(Bristow::Function) do
        function_name "test_function"
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

    let(:agent_with_functions) do
      func = test_function
      Class.new(Bristow::Agent) do
        agent_name "Function Agent"
        provider :openai
        functions [func]
      end.new
    end

    it "formats functions using provider's format_functions method" do
      mock_client = instance_double(Bristow::Providers::Openai)
      allow(mock_client).to receive(:format_functions)
        .with([test_function])
        .and_return({ functions: ["formatted"], function_call: "auto" })

      agent_with_functions.instance_variable_set(:@client, mock_client)

      result = agent_with_functions.formatted_functions

      expect(result).to eq({ functions: ["formatted"], function_call: "auto" })
    end
  end

  describe "chat method with different providers" do
    let(:messages) { [{ "role" => "user", "content" => "Hello" }] }

    describe "OpenAI provider" do
      let(:agent) do
        Class.new(Bristow::Agent) do
          agent_name "OpenAI Test Agent"
          provider :openai
          model "gpt-4o-mini"
        end.new
      end

      it "calls OpenAI provider's chat method" do
        mock_client = instance_double(Bristow::Providers::Openai)
        allow(mock_client).to receive(:format_functions).and_return({})
        allow(mock_client).to receive(:chat)
          .with(hash_including(model: "gpt-4o-mini"))
          .and_return({ "role" => "assistant", "content" => "Hello from OpenAI!" })
        allow(mock_client).to receive(:is_function_call?).and_return(false)

        agent.instance_variable_set(:@client, mock_client)

        response = agent.chat("Hello")

        expect(response).to include(
          a_hash_including(
            "role" => "assistant",
            "content" => "Hello from OpenAI!"
          )
        )
      end

      it "calls OpenAI provider's stream_chat method when block given" do
        mock_client = instance_double(Bristow::Providers::Openai)
        allow(mock_client).to receive(:format_functions).and_return({})
        allow(mock_client).to receive(:stream_chat) do |params, &block|
          block.call("Hello ") if block
          block.call("from ") if block
          block.call("OpenAI!") if block
          { "role" => "assistant", "content" => "Hello from OpenAI!" }
        end
        allow(mock_client).to receive(:is_function_call?).and_return(false)

        agent.instance_variable_set(:@client, mock_client)

        streamed_content = []
        response = agent.chat("Hello") { |chunk| streamed_content << chunk }

        expect(streamed_content).to eq(["Hello ", "from ", "OpenAI!"])
        expect(response).to include(
          a_hash_including(
            "role" => "assistant",
            "content" => "Hello from OpenAI!"
          )
        )
      end
    end

    describe "Anthropic provider" do
      let(:agent) do
        Class.new(Bristow::Agent) do
          agent_name "Anthropic Test Agent"
          provider :anthropic
          model "claude-3-sonnet-20240229"
        end.new
      end

      it "calls Anthropic provider's methods" do
        mock_client = instance_double(Bristow::Providers::Anthropic)
        allow(mock_client).to receive(:format_functions).and_return({})
        allow(mock_client).to receive(:chat)
          .and_raise(NotImplementedError, "Anthropic provider not yet implemented")

        agent.instance_variable_set(:@client, mock_client)

        expect { agent.chat("Hello") }.to raise_error(NotImplementedError, "Anthropic provider not yet implemented")
      end
    end
  end

  describe "backward compatibility" do
    it "maintains existing OpenAI functionality" do
      # Create agent without specifying provider (should default to OpenAI)
      agent_class = Class.new(Bristow::Agent) do
        agent_name "Legacy Agent"
        model "gpt-3.5-turbo"
        system_message "Legacy agent"
      end

      agent = agent_class.new

      expect(agent.provider).to eq(:openai)
      expect(agent.model).to eq("gpt-3.5-turbo")
      expect(agent.client).to be_a(Bristow::Providers::Openai)
    end

    it "works with existing configuration methods" do
      # This should work as before
      expect(Bristow.configuration.client).to be_a(Bristow::Providers::Openai)
      expect(Bristow.configuration.model).to eq("gpt-4o-mini") # OpenAI default
    end
  end

  describe "configuration changes affect new agents" do
    it "new agents use updated default provider" do
      agent_class = Class.new(Bristow::Agent) do
        agent_name "Dynamic Agent"
      end

      # Change default provider
      Bristow.configure do |config|
        config.default_provider = :anthropic
      end

      agent = agent_class.new

      expect(agent.provider).to eq(:anthropic)
      expect(agent.client).to be_a(Bristow::Providers::Anthropic)
    end
  end
end