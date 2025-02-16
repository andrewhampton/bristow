module Bristow
  module Agencies
    class Workflow < Agency
      def chat(messages, &block)
        return messages if agents.empty?

        agents.each.with_index(1) do |agent, index|
          last = index == agents.size
          messages = agent.chat(messages, &(last ? block : nil))
        end

        messages
      end
    end
  end
end
