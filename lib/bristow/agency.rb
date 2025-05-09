module Bristow
  class Agency
    include Bristow::Sgetter

    sgetter :agents, default: []

    def initialize(agents: self.class.agents.dup)
      @agents = agents
    end

    def self.chat(...)
      new.chat(...)
    end

    def chat(messages, &block)
      raise NotImplementedError, "#{self.class.name}#chat must be implemented"
    end

    def find_agent(name)
      agent = agents.find { |agent| agent_name_for(agent) == name }
      return nil unless agent
      
      agent.is_a?(Class) ? agent.new : agent
    end

    protected

    def call_agent(agent, messages, &block)
      response = agent.chat(messages, &block)
      response.last # Return just the last message
    end

    private

    def agent_name_for(agent)
      agent.is_a?(Class) ? agent.agent_name : agent.class.agent_name
    end
  end
end
