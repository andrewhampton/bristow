require_relative "../lib/bristow"

Bristow.configure do |config|
    config.default_model = 'gpt-4o-mini'
end

# Define functions that GPT can call
weather = Bristow::Function.new(
  name: "get_weather",
  description: "Get the current weather for a location",
  parameters: {
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
  }
) do |location:, unit: 'celsius'|
  # Your weather API call here
  { temperature: 22, unit: unit }
end

# Create an agent with these functions
weather_agent = Bristow::Agent.new(
  name: "WeatherAssistant",
  description: "Helps with weather-related queries",
  functions: [weather]
)

# Start a conversation
messages = [
  { "role" => "user", "content" => "What's the weather like in London?" }
]

messages_from_chat = weather_agent.chat(messages) do |part|
  print part
end

puts ''
puts '*' * 10
puts 'All messages:'
pp messages
