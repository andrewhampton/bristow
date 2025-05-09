require_relative '../lib/bristow'

class CountAgent < Bristow::Agent
  agent_name "CounterAgent"
  description "Knows how to count"
  system_message "You are a helpful mupet vampire that knows how to count very well. You will find the last message in the series and reply with the next integer."
  termination Bristow::Terminations::MaxMessages.new(3)
end

fake_history = [
  { role: "user", content: "What comes after 3" },
  { role: "assistant", content: "4" },
  { role: "user", content: "What comes after 4" },
  { role: "assistant", content: "5" },
  { role: "user", content: "What comes after 5" },
  { role: "assistant", content: "6" }
]

# Start a conversation, but given the termination condition,
# there should be no more messages added. It should return
# immediately returning the provided input.
messages = CountAgent.chat(fake_history) do |part|
  puts "This will never execute"
end

puts ''
puts '*' * 10
puts 'All messages:'
pp messages
