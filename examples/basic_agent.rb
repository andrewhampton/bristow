require_relative "../lib/bristow"

Bristow.configure do |config|
    config.default_model = 'gpt-4o-mini'
end

sydney = Bristow::Agent.new(
  name: 'Sydney',
  description: 'Agent for telling spy stories',
  system_message: 'Given a topic, you will tell a brief spy story',
)

sydney.chat([{role: 'user', content: 'Cold war era Berlin'}]) do |part|
  print part
end