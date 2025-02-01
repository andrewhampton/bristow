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

```ruby
require 'bristow'

# Configure Bristow
Bristow.configure do |config|
  config.api_key = ENV['OPENAI_API_KEY']
end

# Define functions that the model can call
class WeatherLookup < Bristow::Function
  name "get_weather"
  description "Get the current weather for a location"
  system_message "You are a weather forecast assistant. Given a location, you will look up the weather forecast and provide a brief description."
  parameters { 
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
    required: ["location"]
  }

  def perform(location:, unit: 'celsius')
    # Implement your application logic here
    { temperature: 22, unit: unit }
  end
end

# Create an agent with access to the function
class Forecaster < Bristow::Agent
  name "WeatherAssistant"
  description "Helps with weather-related queries"
  system_message "You are a weather forecast assistant. Given a location, you will look up the weather forecast and provide a brief description."
  functions [WeatherLookup]
end

# Chat with the agent
forecaster_agent = Forecaster.new
forecaster_agent.chat("What's the weather like in London?") do |response_chunk|
  # As the agent streams the response, print each chunk
  print response_chunk 
end

# Create a more complex agent that can access multiple functions
class WeatherDatabase < Bristow::Function
  name "store_weather"
  description "Store weather data in the database"
  parameters {
    properties: {
      location: {
        type: "string",
        description: "The city and state, e.g. San Francisco, CA"
      },
      temperature: {
        type: "number",
        description: "The temperature in the specified unit"
      },
      unit: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "The unit of temperature"
      }
    },
    required: ["location", "temperature", "unit"]
  }

  def self.perform(location:, temperature:, unit:)
    # Store the weather data in your database
    { status: "success", message: "Weather data stored for #{location}" }
  end
end

class WeatherManager < Bristow::Agent
  name "WeatherManager"
  description "Manages weather data collection and storage"
  system_message "You are a weather data management assistant. You can look up weather data and store it in the database."
  functions [WeatherLookup, WeatherDatabase]
end

# Create an agency to coordinate multiple agents. The supervisor agent is a
# pre-configured agency that includes a supervisor agent that knows how to
# delegate tasks to other agents
class WeatherAgency < Bristow::Agencies::Supervisor
  agents [Forecaster, WeatherManager]
end

# Use the agency to coordinate multiple agents
agency = WeatherAgency.new
agency.chat("Can you check the weather in London and store it in the database?") do |response_chunk|
  print response_chunk
end
```

## Examples

A few working examples are in the `examples/` directory. If you have `OPENAI_API_KEY` set in the environment, you can run the examples with with `bundle exec ruby examples/<example file>.rb` to get a taste of Bristow.

## Configuration

Configure Bristow with your settings:

```ruby
Bristow.configure do |config|
  # Your OpenAI API key (defaults to ENV['OPENAI_API_KEY'])
  config.openai_api_key = 'your-api-key'
  
  # The default model to use (defaults to 'gpt-4o-mini')
  config.model = 'gpt-4o'
  
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
