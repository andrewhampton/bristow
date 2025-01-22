module Bristow
  module Agents
    class Supervisor < Agent
      attr_accessor :agency

      def initialize(available_agents:, agency: nil, name: "Supervisor", description: "A supervisor agent that coordinates between specialized agents", model: Bristow.configuration.default_model)
        super(
          name: name,
          description: description,
          system_message: system_prompt(available_agents),
          functions: [delegate_function],
          model: model
        )
        @agency = agency
      end

      private

      def system_prompt(available_agents)
        agent_descriptions = available_agents
          .reject { |agent| agent.name == name }
          .map { |agent| "- #{agent.name}: #{agent.description}" }
          .join("\n")

        <<~PROMPT
          You are a supervisor agent that coordinates between specialized agents.
          Your role is to:
          1. Understand the user's request
          2. Choose the most appropriate agent to handle it
          3. Delegate using the delegate_to function
          4. Review the agent's response
          5. Either return the response to the user or delegate to another agent

          Available agents:
          #{agent_descriptions}

          Always use the delegate_to function to work with other agents.
          After receiving a response, you can either:
          1. Return it to the user if it fully answers their request
          2. Delegate to another agent if more work is needed
          3. Add your own clarification or summary if needed
        PROMPT
      end

      def delegate_function
        Function.new(
          name: "delegate_to",
          description: "Delegate a task to a specialized agent",
          parameters: {
            agent_name: String,
            message: String
          }
        ) do |agent_name:, message:|
          raise "No agency set for supervisor" unless agency
          
          agent = agency.find_agent(agent_name)
          raise ArgumentError, "Agent #{agent_name} not found" unless agent
          
          # Don't delegate to self
          return { error: "Cannot delegate to self" } if agent == self

          Bristow.configuration.logger.info("Delegating to #{agent_name}: #{message}")
          
          response = agent.chat([{ "role" => "user", "content" => message }])
          { response: response.last["content"] }
        end
      end
    end
  end
end