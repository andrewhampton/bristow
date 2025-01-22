# frozen_string_literal: true

RSpec.describe Bristow do
  it "has a version number" do
    expect(Bristow::VERSION).not_to be nil
  end

  it "creates a supervisor agency" do
    agency = Bristow::Agencies::Supervisor.create(agents: [])
    expect(agency).to be_a(Bristow::Agencies::Supervisor)
  end

  describe ".configure" do
    after(:each) do
      Bristow.reset_configuration!
    end

    it "allows setting configuration values" do
      Bristow.configure do |config|
        config.openai_api_key = "test-key"
        config.default_model = "gpt-4"
      end

      expect(Bristow.configuration.openai_api_key).to eq("test-key")
      expect(Bristow.configuration.default_model).to eq("gpt-4")
    end

    it "resets the client when api key is updated" do
      old_client = Bristow.configuration.client
      Bristow.configuration.openai_api_key = "new-key"
      expect(Bristow.configuration.client).not_to eq(old_client)
    end

    it "resets configuration to default values" do
      Bristow.configure do |config|
        config.openai_api_key = "test-key"
        config.default_model = "gpt-4"
      end

      Bristow.reset_configuration!

      expect(Bristow.configuration.openai_api_key).to eq(ENV["OPENAI_API_KEY"])
      expect(Bristow.configuration.default_model).to eq("gpt-4o-mini")
    end
  end
end
