module Bristow
  class Agency
    attr_reader :agents

    def initialize(agents: [])
      @agents = agents
    end

    def chat(messages, &block)
      raise NotImplementedError, "Agency#chat must be implemented by a subclass"
    end

    def find_agent(name)
      agents.find { |agent| agent.name == name }
    end

    protected

    def call_agent(agent, messages, &block)
      response = agent.chat(messages, &block)
      response.last # Return just the last message
    end
  end
end
