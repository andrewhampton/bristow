# Bristow

Bristow makes working with AI models in your application dead simple. Whether it's a simple chat, using function calls, or building multi-agent systems, Bristow will help you hit the ground running.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bristow'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bristow

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

# Either stream the response with a block:
storyteller.chat('Tell me a story about Cold War era Berlin') do |response_chunk|
  print response_chunk # response_chunk will be the next chunk of text in the response from the model
end

# Or work with the entire conversation once it's complete:
conversation = storyteller.chat('Tell me a story about Cold War era Berlin')
puts conversation.last['content'] 
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
  # Implement your application logic here
  { temperature: 22, unit: unit }
end

# Create an agent with access to the function
weather_agent = Bristow::Agent.new(
  name: "WeatherAssistant",
  description: "Helps with weather-related queries",
  functions: [weather]
)

# Chat with the agent
weather_agent.chat("What's the weather like in London?") do |response_chunk|
  print response_chunk 
end
```

### Multi-Agent System

You can coordinate multiple agents using `Bristow::Agency`. Bristow includes a few common patterns, including the one like [langchain's multi-agent supervisor](https://langchain-ai.github.io/langgraph/tutorials/multi_agent/agent_supervisor/). Here's how to use the supervisor agency:

```ruby
# Create specialized agents. These can be configured with functions, as well.
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

# The supervisor will automatically delegate to the appropriate agent as needed before generating a response for the user.
agency.chat([
  { role: "user", content: "I want to go to New York. Tell me about it as if you were a pirate." }
]) do |response_chunk|
  print response_chunk
end
```

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

# You can overrided these settings on a per-agent basis like this:
storyteller = Bristow::Agent.new(
  name: 'Sydney',
  description: 'Agent for telling spy stories',
  system_message: 'Given a topic, you will tell a brief spy story',
  model: 'gpt-4o-mini',
  logger: Logger.new(STDOUT)
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrewhampton/bristow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bristow project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).
