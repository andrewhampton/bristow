# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bristow"
require "webmock/rspec"

# Disable all real network connections
WebMock.disable_net_connect!






RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end


end

Bristow.configure do |config|
  config.logger = Logger.new(File::NULL)
  config.openai_api_key = "test_api_key"
end
