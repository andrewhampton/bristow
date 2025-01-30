module Bristow
  module Agents
    class Supervisor < Agent
      attr_accessor :agency

      def initialize(available_agents:, agency: nil, name: "Supervisor", description: "A supervisor agent that coordinates between specialized agents", model: Bristow.configuration.default_model)
        super(
          name: name,
          description: description,
          system_message: build_system_message(available_agents),
          functions: [delegate_function],
          model: model
        )
        @agency = agency
      end

      private

      def build_system_message(available_agents)
        agent_descriptions = available_agents.map do |agent|
          "- #{agent.name}: #{agent.description}"
        end.join("\n")

        <<~MESSAGE
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
        MESSAGE
      end

      def delegate_function
        Function.new(
          name: "delegate_to",
          description: "Delegate a task to a specialized agent",
          parameters: {
            properties: {
              agent_name: {
                type: "string",
                description: "The name of the agent to delegate to"
              },
              message: {
                type: "string",
                description: "The instructions for the agent being delegated to"
              }
            }
          }
        ) do |agent_name:, message:|
          raise "No agency set for supervisor" unless agency

          if agent_name == name
            { error: "Cannot delegate to self" }
          else
            agent = agency.find_agent(agent_name)
            raise ArgumentError, "Agent #{agent_name} not found" unless agent

            Bristow.configuration.logger.info("Delegating to #{agent_name}: #{message}")
            response = agent.chat([{ "role" => "user", "content" => message }])
            { response: response.last["content"] }
          end
        end
      end
    end
  end
end
