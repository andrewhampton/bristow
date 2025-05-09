require_relative '../lib/bristow'

Bristow.configure do |config|
    config.model = 'gpt-4o-mini'
end

# Define functions that GPT can call
class WeatherLookup < Bristow::Function
  function_name "get_weather"
  description "Get the current weather for a location"
  parameters ({
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "The city and state, e.g. San Francisco, CA"
      },
      unit: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "The unit of temperature to return"
      }
    },
    required: [:location]
  })

  def perform(location:, unit: 'celsius')
    # Your weather API call here
    { temperature: 22, unit: unit }
  end
end

# Create an agent with these functions
class WeatherAgent < Bristow::Agent
  agent_name "WeatherAssistant"
  description "Helps with weather-related queries"
  system_message "You are a helpful weather assistant. You'll be asked about the weather, and should use the get_weather function to respond."
  functions [WeatherLookup]
end

# Start a conversation
messages = WeatherAgent.chat("What's the weather like in London?") do |part|
  print part
end

puts ''
puts '*' * 10
puts 'All messages:'
pp messages
