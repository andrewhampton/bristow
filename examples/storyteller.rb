require_relative "../lib/bristow"

sydney = Bristow::Agent.new(
  name: 'Sydney',
  description: 'Agent for telling spy stories',
  system_message: 'Given a topic, you will tell a brief spy story',
)

pp sydney.chat([{role: 'user', content: 'Cold war era Berlin'}])