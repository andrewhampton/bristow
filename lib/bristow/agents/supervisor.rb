# frozen_string_literal: true

module Bristow
  module Agents
    class Supervisor < Agent
      attr_reader :agency

      agent_name "Supervisor"
      description "A supervisor agent that coordinates between specialized agents"
      system_message <<~MESSAGE
        You are a supervisor agent that coordinates between specialized agents.
        Your role is to:
        1. Understand the user's request
        2. Choose the most appropriate agent to handle it
        3. Delegate using the delegate_to function
        4. Review the agent's response
        5. Either return the response to the user or delegate to another agent

        After receiving a response, you can either:
        1. Return it to the user if it fully answers their request
        2. Delegate to another agent if more work is needed
        3. Add your own clarification or summary if needed
      MESSAGE

      sgetter :custom_instructions, default: nil

      def initialize(child_agents:, agency:, custom_instructions: nil, termination: self.class.termination)
        super()
        @custom_instructions = custom_instructions || self.class.custom_instructions
        @system_message = build_system_message(child_agents)
        @agency = agency
        @custom_instructions = custom_instructions || self.class.custom_instructions
        @termination = termination
        agency.agents << self
        @functions ||= []
        @functions << Functions::Delegate.new(self, agency)
      end

      private

      def build_system_message(available_agents)
        agent_descriptions = available_agents.map do |agent|
          "- #{agent.agent_name}: #{agent.description}"
        end.join("\n")

        <<~MESSAGE
          #{self.class.system_message}

          #{custom_instructions.nil? ? "" : custom_instructions}

          Available agents:
          #{agent_descriptions}

          Always use the delegate_to function to work with other agents.
        MESSAGE
      end
    end
  end
end
