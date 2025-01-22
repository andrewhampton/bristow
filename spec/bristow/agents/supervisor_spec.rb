# frozen_string_literal: true

RSpec.describe Bristow::Agents::Supervisor do
  let(:weather_agent) do
    Bristow::Agent.new(
      name: "WeatherBot",
      description: "Handles weather queries",
      functions: [
        Bristow::Function.new(
          name: "get_weather",
          description: "Get weather",
          parameters: { location: String }
        ) { |location:| { weather: "sunny" } }
      ]
    )
  end

  let(:math_agent) do
    Bristow::Agent.new(
      name: "MathBot",
      description: "Handles math calculations"
    )
  end

  let(:agency) { Bristow::Agencies::Supervisor.create(agents: available_agents) }
  let(:available_agents) { [weather_agent, math_agent] }

  subject(:supervisor) { agency.supervisor }

  describe "#initialize" do
    it "creates a supervisor with available agents" do
      expect(supervisor.name).to eq("Supervisor")
      expect(supervisor.description).to match(/coordinates between specialized agents/)
    end

    it "includes agent descriptions in system message" do
      expect(supervisor.instance_variable_get(:@system_message))
        .to include("WeatherBot: Handles weather queries")
        .and include("MathBot: Handles math calculations")
    end

    it "sets up delegation function" do
      expect(supervisor.functions.first.name).to eq("delegate_to")
    end
  end

  describe "delegation", :vcr do
    let(:delegate_fn) { supervisor.functions.first }

    it "delegates to the specified agent" do
      result = delegate_fn.call(
        agent_name: "WeatherBot",
        message: "What's the weather in New York?"
      )
      expect(result[:response]).to include("sunny")
    end

    it "raises error when agency not set" do
      supervisor.agency = nil
      expect {
        delegate_fn.call(
          agent_name: "WeatherBot",
          message: "What's the weather?"
        )
      }.to raise_error(/No agency set/)
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
      expect(result[:error]).to eq("Cannot delegate to self")
    end
  end
end
