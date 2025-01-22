# Bristow

Bristow is a Ruby framework for creating function-calling enabled agents that work with OpenAI's GPT models. It provides a simple way to expose Ruby functions to GPT, handle the function calling protocol, and manage conversations.

## Features

- 🤖 Simple function-calling interface for GPT models
- 🔄 Automatic handling of OpenAI's function calling protocol
- 🛠 Type-safe function definitions
- 🔌 Easy to extend with custom functions
- 📝 Clean conversation management

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
  
  # The default model to use (defaults to 'gpt-4')
  config.default_model = '4o-mini'
  
  # Logger to use (defaults to Logger.new(STDOUT))
  config.logger = Rails.logger
end
```

These settings can be overridden on a per-agent basis when needed.

## Usage

### Creating Functions and Agents

```ruby
require 'bristow'

# Define functions that GPT can call
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

# Start a conversation
messages = [
  { "role" => "user", "content" => "What's the weather like in London?" }
]

# The client will:
# 1. Send the message to GPT
# 2. If GPT calls a function, route it to the appropriate function
# 3. Add the function result to the conversation
# 4. Return the updated messages array
messages = weather_agent.chat(messages)
```

### Multiple Functions

```ruby
# Define multiple functions for an agent
translate = Bristow::Function.new(
  name: "translate",
  description: "Translate text to another language",
  parameters: {
    text: String,
    target_language: String
  }
) do |text:, target_language:|
  # Your translation API call here
  "Translated text"
end

summarize = Bristow::Function.new(
  name: "summarize",
  description: "Summarize a piece of text",
  parameters: {
    text: String,
    max_length: Integer
  }
) do |text:, max_length:|
  # Your summarization logic here
  "Summary of text"
end

# Create an agent with multiple functions
language_agent = Bristow::Agent.new(
  name: "LanguageAssistant",
  description: "Helps with language-related tasks",
  functions: [translate, summarize]
)
```

### Agent Handoffs

You can chain agents together to handle complex workflows:

```ruby
# Create agents for different tasks
supervisor = Bristow::Agent.new(
  name: "Supervisor",
  description: "Supervises agents",
  system_message: "You are a supervisor for agents"
)

researcher = Bristow::Agent.new(
  name: "Researcher",
  description: "Finds information",
  system_message: "You are a researcher. Given a topic, you will research it.",
  functions: [search, fetch_content]
)

summarizer = Bristow::Agent.new(
  name: "Summarizer",
  description: "Summarizes content",
  system_message: "You are a summarizer. Given a piece of text, you will summarize it.",
  functions: [summarize, translate]
)

agency = Bristow::Agencies::Supervisor.new(
    supervisor: supervisor,
    agents: [researcher, summarizer],
    strategy: :round_robin
)

# Will call the supervisor, which may choose to hand off to any other agent repeatedly until the task is completed.
agency.handle_message({ role: "user", content: "What is the current weather in London? Please provide the answer in Spanish." }) 

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrewhampton/bristow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bristow project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrewhampton/bristow/blob/main/CODE_OF_CONDUCT.md).
