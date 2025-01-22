module Bristow
  module Agencies
    class Supervisor < Agency
      attr_accessor :supervisor

      def self.create(agents: [])
        agency = new(agents: agents)
        supervisor = Agents::Supervisor.new(
          available_agents: agents,
          agency: agency
        )
        agency.supervisor = supervisor
        agency.agents << supervisor
        agency
      end

      def initialize(agents: [])
        @agents = agents
        @supervisor = nil  # Will be set by create
      end

      def chat(messages, &block)
        raise "No supervisor set" unless supervisor

        # Convert string message to proper format
        messages = [{ role: "user", content: messages }] if messages.is_a?(String)
        
        # Convert array of strings to proper format
        messages = messages.map { |msg| msg.is_a?(String) ? { role: "user", content: msg } : msg } if messages.is_a?(Array)

        supervisor.chat(messages, &block)
      end
    end
  end
end
