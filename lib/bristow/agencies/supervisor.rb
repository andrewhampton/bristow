module Bristow
  module Agencies
    class Supervisor < Agency
      attr_reader :supervisor

      sgetter :custom_instructions, default: nil

      def initialize(agents: self.class.agents.dup, custom_instructions: self.class.custom_instructions, termination: Bristow::Terminations::MaxMessages.new(100))
        @custom_instructions = custom_instructions
        @agents = agents
        @termination = termination
        @supervisor = Agents::Supervisor.new(
          child_agents: agents,
          agency: self,
          custom_instructions: custom_instructions,
          termination: termination
        )
      end

      def chat(messages, &block)
        raise "Supervisor not set" unless supervisor

        # Convert string message to proper format
        messages = [{ role: "user", content: messages }] if messages.is_a?(String)

        supervisor.chat(messages, &block)
      end
    end
  end
end
