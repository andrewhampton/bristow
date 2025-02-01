require_relative '../lib/bristow'

Bristow.configure do |config|
    config.model = 'gpt-4o-mini'
end

class Sydney < Bristow::Agent
  name 'Sydney'
  description 'Agent for telling spy stories'
  system_message 'Given a topic, you will tell a brief spy story'
end

sydney = Sydney.new

begin
  sydney.chat([{role: 'user', content: 'Cold war era Berlin'}]) do |part|
    print part
  end

rescue SystemStackError => e
  puts e.backtrace.join("\n")
end
