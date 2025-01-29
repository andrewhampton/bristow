# frozen_string_literal: true

RSpec.describe Bristow::Agencies::Supervisor do
  let(:weather_agent) do
    Bristow::Agent.new(
      name: "WeatherBot",
      description: "Handles weather queries"
    )
  end

  let(:math_agent) do
    Bristow::Agent.new(
      name: "MathBot",
      description: "Handles math calculations"
    )
  end

  let(:agents) { [weather_agent, math_agent] }

  describe ".create" do
    subject(:agency) { described_class.create(agents: agents) }

    it "creates an agency with the given agents" do
      expect(agency.agents).to include(weather_agent, math_agent)
    end

    it "creates and sets up a supervisor" do
      expect(agency.supervisor).to be_a(Bristow::Agents::Supervisor)
      expect(agency.supervisor.agency).to eq(agency)
    end
  end

  describe "#chat", :vcr do
    subject(:agency) { described_class.create(agents: agents) }
    let(:messages) { [{ "role" => "user", "content" => "Hello" }] }
    let(:block) { proc { |part| @streamed_parts ||= []; @streamed_parts << part } }

    it "delegates chat to supervisor" do
      agency.chat(messages, &block)
      expect(@streamed_parts).not_to be_empty
    end

    it "delegates chat to supervisor", vcr: { cassette_name: "bristow_agencies_supervisor_chat_delegates_chat_to_supervisor_base" } do
      response = []
      agency.chat([{ role: "user", content: "What's the weather in New York?" }]) do |part|
        response << part
      end
      expect(response.join).not_to be_empty
    end

    it "accepts a string message", vcr: { cassette_name: "bristow_agencies_supervisor_chat_accepts_string_message" } do
      response = []
      agency.chat("What's the weather in New York?") do |part|
        response << part
      end
      expect(response.join).not_to be_empty
    end

    it "raises error when supervisor not set" do
      agency.supervisor = nil
      expect {
        agency.chat(messages, &block)
      }.to raise_error(/No supervisor set/)
    end

    it "handles array and non-array messages" do
      # String message
      agency.chat("Hello", &block)
      expect(@streamed_parts).not_to be_empty

      # Array of hashes
      @streamed_parts = []
      agency.chat([{ "role" => "user", "content" => "Hello" }], &block)
      expect(@streamed_parts).not_to be_empty
    end
  end
end
