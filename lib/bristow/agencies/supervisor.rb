module Bristow
  module Agencies
    class Supervisor < Agency
      attr_accessor :supervisor

      def self.create(agents:)
        agency = new(agents: agents)
        supervisor = Agents::Supervisor.new(
          available_agents: agents,
          agency: agency
        )
        agency.supervisor = supervisor
        agency
      end

      def initialize(agents:)
        @agents = agents
        @supervisor = nil  # Will be set by create
      end

      def chat(message, &block)
        raise "No supervisor set" unless supervisor
        messages = message.is_a?(Array) ? message : [message]
        supervisor.chat(messages, &block)
      end
    end
  end
end
