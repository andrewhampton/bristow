# frozen_string_literal: true

RSpec.describe Bristow::Providers::Google do
  let(:provider) { described_class.new(api_key: "test-google-key") }

  describe "#default_model" do
    it "returns gemini-pro" do
      expect(provider.default_model).to eq("gemini-pro")
    end
  end

  describe "methods not yet implemented" do
    it "raises NotImplementedError for #chat" do
      expect { provider.chat({}) }.to raise_error(NotImplementedError, "Google provider not yet implemented")
    end

    it "raises NotImplementedError for #stream_chat" do
      expect { provider.stream_chat({}) }.to raise_error(NotImplementedError, "Google provider not yet implemented")
    end

    it "raises NotImplementedError for #format_functions" do
      expect { provider.format_functions([]) }.to raise_error(NotImplementedError, "Google provider not yet implemented")
    end
  end
end