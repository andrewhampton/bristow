# frozen_string_literal: true
require 'openai'
require 'logger'
require 'json'

require_relative "bristow/version"
require_relative "bristow/helpers/sgetter"
require_relative "bristow/helpers/delegate"
require_relative "bristow/configuration"
require_relative "bristow/function"
require_relative "bristow/functions/delegate"
require_relative "bristow/agent"
require_relative "bristow/agents/supervisor"
require_relative "bristow/agency"
require_relative "bristow/agencies/supervisor"
require_relative "bristow/agencies/workflow"
require_relative "bristow/termination"
require_relative "bristow/terminations/max_messages"
require_relative "bristow/terminations/timeout"
require_relative "bristow/terminations/can_not_stop_will_not_stop"

module Bristow
  class Error < StandardError; end
end
