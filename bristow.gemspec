# frozen_string_literal: true

require_relative "lib/bristow/version"

Gem::Specification.new do |spec|
  spec.name = "bristow"
  spec.version = Bristow::VERSION
  spec.authors = ["Andrew Hampton"]
  spec.email = ["bristow@awh.dev"]

  spec.summary = "A Ruby framework for creating systems of cooperative AI agents with function calling capabilities"
  spec.description = "Bristow provides a flexible framework for creating and managing systems of agents that can work together, hand off tasks between each other, and execute functions. Perfect for building complex AI systems and automation workflows."
  spec.homepage = "https://github.com/andrewhampton/bristow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/andrewhampton/bristow"
  spec.metadata["changelog_uri"] = "https://github.com/andrewhampton/bristow/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-openai", "~> 7.0.0"

  spec.add_development_dependency "debug", "~> 1.10"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
