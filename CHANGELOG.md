## [Unreleased]

## [1.0.0] - 2025-05-26

- Drop support for ruby 3.0 and 3.1
- Add Anthropic API support

## [0.5.1] - 2025-05-08

- Improve publish script

## [0.5.0] - 2025-05-08

- Add termination conditions so you can ensure an agent stop after a certain amount of time.
- Drop VCR in favor of WebMock for testing
- Fix `name` shadowing the built-in function for agent and function

## [0.4.0] - 2025-02-15

- Update the README to make it flow a bit better.
- Add .chat to Agent
- Give functions a default name that is the name of the class
- Add the workflow agency

## [0.3.1] - 2025-02-01

- Dropped errant require of 'debug'

## [0.3.0] - 2025-02-01

- Major update to the API. Now primarily class based.
  Check the README for new details.

- Require updating CHANGELOG.md in each PR, but only in PRs.

## [0.2.1] - 2025-01-29

- Fixed schema for supervisor agent function call

## [0.2.0] - 2025-01-28

- Refactored the schema for function calls

## [0.1.0] - 2025-01-21

- Initial release
