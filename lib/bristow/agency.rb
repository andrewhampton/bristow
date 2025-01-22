module Bristow
  class Agency
    attr_reader :agents

    def initialize(agents: [])
      @agents = agents
    end

    def chat(messages, &block)
      # Convert string message to proper format
      messages = [{ role: "user", content: messages }] if messages.is_a?(String)
      
      # Convert array of strings to proper format
      messages = messages.map { |msg| msg.is_a?(String) ? { role: "user", content: msg } : msg } if messages.is_a?(Array)

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
