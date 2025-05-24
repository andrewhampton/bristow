require_relative '../lib/bristow'

Bristow.configure do |config|
  # Set provider based on environment variable, default to OpenAI
  provider = ENV['BRISTOW_PROVIDER']&.to_sym || :openai
  config.default_provider = provider

  case provider
  when :anthropic
    config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  when :openai
    config.model = 'gpt-4o-mini'
  end
end

class Sydney < Bristow::Agent
  agent_name 'Sydney'
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
