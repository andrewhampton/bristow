require_relative '../lib/bristow'

class TravelAgent < Bristow::Agent
  name "TravelAgent"
  description "Agent for planning trips"
  system_message 'Given a destination, you will plan a trip. You will respond with an itinerary that includes dates, times, and locations only.'
end

class StoryTeller < Bristow::Agent
  name "StoryTeller"
  description 'An agent that tells a story given an agenda'
  system_message "Given a trip agenda, you will tell a story about a traveler who recently took that trip. Be sure to highlight the traveler's experiences and emotions."
end

# The workflow agent implements basic workflow. It will call each agent in the
# order they are listed, passing the message history to each agent. The response
# from the last agent is streamed to the block passed to chat, but the entire
# message history is returned.
workflow = Bristow::Agencies::Workflow.new(agents: [TravelAgent, StoryTeller])

messages = workflow.chat('New York') do |part|
  print part
end

puts '*' * 80
puts 'Chat history:'
pp messages
