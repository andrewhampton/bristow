# frozen_string_literal: true

RSpec.describe Bristow::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.default_provider).to eq(:openai)
      expect(config.default_model).to be_nil
      expect(config.clients).to eq({})
      expect(config.logger).to be_a(Logger)
    end

    it "reads API keys from environment" do
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('env-openai-key')
      allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('env-anthropic-key')
      allow(ENV).to receive(:[]).with('GOOGLE_API_KEY').and_return('env-google-key')

      config = described_class.new

      expect(config.openai_api_key).to eq('env-openai-key')
      expect(config.anthropic_api_key).to eq('env-anthropic-key')
      expect(config.google_api_key).to eq('env-google-key')
    end
  end

  describe "API key setters" do
    it "resets client when OpenAI API key changes" do
      config.openai_api_key = "old-key"
      config.client_for(:openai) # This creates the client

      expect(config.clients[:openai]).to be_a(Bristow::Providers::Openai)

      config.openai_api_key = "new-key"

      expect(config.clients[:openai]).to be_nil
    end

    it "resets client when Anthropic API key changes" do
      config.anthropic_api_key = "old-key"
      config.client_for(:anthropic) # This creates the client

      expect(config.clients[:anthropic]).to be_a(Bristow::Providers::Anthropic)

      config.anthropic_api_key = "new-key"

      expect(config.clients[:anthropic]).to be_nil
    end

    it "resets client when Google API key changes" do
      config.google_api_key = "old-key"
      config.client_for(:google) # This creates the client

      expect(config.clients[:google]).to be_a(Bristow::Providers::Google)

      config.google_api_key = "new-key"

      expect(config.clients[:google]).to be_nil
    end
  end

  describe "#client_for" do
    before do
      config.openai_api_key = "test-openai-key"
      config.anthropic_api_key = "test-anthropic-key"
      config.google_api_key = "test-google-key"
    end

    it "creates and caches OpenAI provider" do
      client = config.client_for(:openai)

      expect(client).to be_a(Bristow::Providers::Openai)
      expect(config.client_for(:openai)).to be(client) # Same instance
    end

    it "creates and caches Anthropic provider" do
      client = config.client_for(:anthropic)

      expect(client).to be_a(Bristow::Providers::Anthropic)
      expect(config.client_for(:anthropic)).to be(client) # Same instance
    end

    it "creates and caches Google provider" do
      client = config.client_for(:google)

      expect(client).to be_a(Bristow::Providers::Google)
      expect(config.client_for(:google)).to be(client) # Same instance
    end

    it "raises error for unknown provider" do
      expect { config.client_for(:unknown) }.to raise_error(ArgumentError, "Unknown provider: unknown")
    end

    it "raises error when API key not configured" do
      config.openai_api_key = nil

      expect { config.client_for(:openai) }.to raise_error(ArgumentError, "OpenAI API key not configured")
    end
  end

  describe "#client (backward compatibility)" do
    before do
      config.openai_api_key = "test-key"
      config.default_provider = :openai
    end

    it "returns client for default provider" do
      client = config.client

      expect(client).to be_a(Bristow::Providers::Openai)
      expect(client).to eq(config.client_for(:openai))
    end
  end

  describe "#model (backward compatibility)" do
    before do
      config.openai_api_key = "test-key"
      config.default_provider = :openai
    end

    it "returns default_model when set" do
      config.default_model = "custom-model"

      expect(config.model).to eq("custom-model")
    end

    it "returns provider's default model when default_model is nil" do
      config.default_model = nil

      expect(config.model).to eq("gpt-4o-mini") # OpenAI provider's default
    end
  end

  describe "#model=" do
    it "sets the default_model" do
      config.model = "custom-model"

      expect(config.default_model).to eq("custom-model")
    end
  end
end