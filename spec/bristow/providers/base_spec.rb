# frozen_string_literal: true

RSpec.describe Bristow::Providers::Base do
  describe "#initialize" do
    it "requires an api_key" do
      expect { described_class.new(api_key: "test-key") }.not_to raise_error
    end

    it "raises error when api_key is nil" do
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError, "API key is required")
    end

    it "raises error when api_key is empty" do
      expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, "API key is required")
    end
  end

  describe "abstract methods" do
    let(:provider) { described_class.new(api_key: "test-key") }

    it "raises NotImplementedError for #chat" do
      expect { provider.chat({}) }.to raise_error(NotImplementedError, "Subclasses must implement #chat")
    end

    it "raises NotImplementedError for #stream_chat" do
      expect { provider.stream_chat({}) }.to raise_error(NotImplementedError, "Subclasses must implement #stream_chat")
    end

    it "raises NotImplementedError for #format_functions" do
      expect { provider.format_functions([]) }.to raise_error(NotImplementedError, "Subclasses must implement #format_functions")
    end

    it "raises NotImplementedError for #default_model" do
      expect { provider.default_model }.to raise_error(NotImplementedError, "Subclasses must implement #default_model")
    end
  end
end