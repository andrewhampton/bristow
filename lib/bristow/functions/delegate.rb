# frozen_string_literal: true

module Bristow
  module Functions
    class Delegate < Function
      function_name "delegate_to"

      def self.description
        "Delegate a task to a specialized agent"
      end

      def self.parameters
        {
          type: "object",
          properties: {
            agent_name: {
              type: "string",
              description: "The name of the agent to delegate to"
            },
            message: {
              type: "string",
              description: "The instructions for the agent being delegated to"
            }
          },
          required: ["agent_name", "message"]
        }
      end

      def description
        self.class.description
      end

      def parameters
        self.class.parameters
      end

      def initialize(agent, agency)
        raise ArgumentError, "Agent must not be nil" if agent.nil?

        @agent = agent
        @agency = agency
        super()
      end

      def agency=(agency)
        @agency = agency
      end

      def perform(agent_name:, message:)
        raise "Agency not set" if @agency.nil?

        if agent_name == @agent.agent_name
          { error: "Cannot delegate to self" }
        else
          agent = @agency.find_agent(agent_name)
          raise ArgumentError, "Agent #{agent_name} not found" unless agent

          Bristow.configuration.logger.info("Delegating to #{agent_name}: #{message}")
          response = agent.chat([{ "role" => "user", "content" => message }])
          last_message = response&.last
          { response: last_message&.[]("content") }
        end
      end
    end
  end
end
