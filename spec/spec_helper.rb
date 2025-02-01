# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bristow"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.filter_sensitive_data("<OPENAI_ORG_ID>") { ENV["OPENAI_ORG_ID"] }

  # Filter organization IDs
  config.filter_sensitive_data("<OPENAI_ORG>") do |interaction|
    interaction.response.headers["Openai-Organization"]&.first
  end

  # Filter cookies and session data
  config.filter_sensitive_data("<COOKIE>") do |interaction|
    interaction.response.headers["Set-Cookie"]&.first&.split(";")&.first
  end

  # Filter request IDs
  config.filter_sensitive_data("<REQUEST_ID>") do |interaction|
    interaction.response.headers["X-Request-Id"]&.first
  end

  # Filter CF-Ray headers
  config.filter_sensitive_data("<CF_RAY>") do |interaction|
    interaction.response.headers["Cf-Ray"]&.first
  end

  # Allow VCR to record new episodes when cassettes don't exist
  config.default_cassette_options = {
    record: :none,
    match_requests_on: [:method, :uri],
    allow_playback_repeats: true
  }

  # Never allow real HTTP connections
  config.allow_http_connections_when_no_cassette = false
end

# Configure WebMock to disallow real network connections
WebMock.disable_net_connect!(
  allow_localhost: true,
  message: "Real HTTP connections are disabled in tests. Use VCR to mock this request:\n" \
          "describe 'your test', :vcr do\n" \
          "  it 'does something' do\n" \
          "    # your test code\n" \
          "  end\n" \
          "end"
)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up VCR cassettes before each test
  config.before(:each) do
    VCR.eject_cassette if VCR.current_cassette
  end

  config.around(:each) do |example|
    if example.metadata[:vcr]
      name = example.metadata[:full_description].downcase.gsub(/[^\w\/]+/, "_")
      VCR.use_cassette(name, &example)
    else
      example.run
    end
  end
end

Bristow.configure do |config|
  config.logger = Logger.new(File::NULL)
end
