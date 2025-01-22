# Bristow

Bristow is a Ruby framework for creating function-calling enabled agents that work with OpenAI's GPT models. It provides a simple way to expose Ruby functions to GPT, handle the function calling protocol, and manage conversations.

## Features

- 🤖 Simple function-calling interface for GPT models
- 🔄 Automatic handling of OpenAI's function calling protocol
- 🛠 Type-safe function definitions
- 🔌 Easy to extend with custom functions
- 📝 Clean conversation management
- 🏢 Multi-agent coordination through agencies

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bristow'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bristow

## Configuration

Configure Bristow with your settings:

```ruby
Bristow.configure do |config|
  # Your OpenAI API key (defaults to ENV['OPENAI_API_KEY'])
  config.openai_api_key = 'your-api-key'
  
  # The default model to use (defaults to 'gpt-4o-mini')
  config.default_model = 'gpt-4o'
  
  # Logger to use (defaults to Logger.new(STDOUT))
  config.logger = Rails.logger
end
```

These settings can be overridden on a per-agent basis when needed.

## Usage

### Simple Agent

You can create agents without functions for basic tasks:

```ruby
require 'bristow'

storyteller = Bristow::Agent.new(
  name: 'Sydney',
  description: 'Agent for telling spy stories',
  system_message: 'Given a topic, you will tell a brief spy story',
)

# Chat with a single message
response = storyteller.chat('Tell me a story about Cold War era Berlin') do |part|
  print part # Stream the response
end

# Chat with multiple messages
response = storyteller.chat([
  'Tell me a story about Cold War era Berlin',
  'Make it about a double agent'
]) do |part|
  print part
end
```

### Basic Agent with Functions

```ruby
# Define functions that the model can call
weather = Bristow::Function.new(
  name: "get_weather",
  description: "Get the current weather for a location",
  parameters: {
    location: String,
    unit: String
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

# Chat with the agent
weather_agent.chat("What's the weather like in London?") do |part|
  print part  # Stream the response
end
```

### Multi-Agent System

You can coordinate multiple agents using agencies. Here's an example using the included supervisor agency:

```ruby
# Create specialized agents
pirate_talker = Bristow::Agent.new(
  name: "PirateSpeaker",
  description: "Agent for translating input to pirate-speak",
  system_message: 'Given a text, you will translate it to pirate-speak.',
)

travel_agent = Bristow::Agent.new(
  name: "TravelAgent",
  description: "Agent for planning trips",
  system_message: 'Given a destination, you will respond with a detailed itenerary that includes only dates, times, and locations.',
)

# Create a supervisor agency to coordinate the agents
agency = Bristow::Agencies::Supervisor.create(agents: [pirate_talker, travel_agent])

# The supervisor will automatically delegate to the appropriate agent.
# In this case, it will almost certainly delegate to the travel_agent first, to get a bulleted itenerary.
# Then, it will delegate to the pirate_talker to translate the itenerary into pirate-speak.
agency.chat([
  { role: "user", content: "I want to go to New York. Tell me about it as if you were a pirate." }
]) do |part|
  print part
end
```

The supervisor will:
1. Understand the user's request
2. Choose the appropriate agent(s)
3. Delegate parts of the task to different agents
4. Combine their responses into a coherent answer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrewhampton/bristow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bristow project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).
