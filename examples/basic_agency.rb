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

class PirateTalker < Bristow::Agent
  agent_name "PirateSpeaker"
  description "Agent for translating input to pirate-speak"
  system_message 'Given a text, you will translate it to pirate-speak.'
end

class TravelAgent < Bristow::Agent
  agent_name "TravelAgent"
  description "Agent for planning trips"
  system_message 'Given a destination, you will plan a trip. You will respond with an itinerary that includes dates, times, and locations only.'
end

class PirateTravelAgency < Bristow::Agencies::Supervisor
  agents [PirateTalker, TravelAgent]
  custom_instructions "Once you know the destination, you should call the TravelAgent to plan the itenerary, then translate the itenerary to pirate-speak using PirateSpeaker before returning it to the user."
end

begin
  messages = PirateTravelAgency.chat("I want to go to New York") do |part|
      print part
  end
rescue SystemStackError => e
  puts e.backtrace.join("\n")
end
pp messages
