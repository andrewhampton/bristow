# Bristow Examples

This directory contains examples demonstrating various features of Bristow.

## Provider Selection

All examples support provider selection via the `BRISTOW_PROVIDER` environment variable:

### OpenAI (default)
```bash
ruby basic_agent.rb
# or explicitly
BRISTOW_PROVIDER=openai ruby basic_agent.rb
```

### Anthropic (Claude)
```bash
BRISTOW_PROVIDER=anthropic ruby basic_agent.rb
```

Make sure to set the appropriate API key:
- `OPENAI_API_KEY` for OpenAI
- `ANTHROPIC_API_KEY` for Anthropic

## Examples

- **basic_agent.rb** - Simple agent that tells spy stories
- **function_calls.rb** - Agent with function calling capabilities (weather lookup)
- **basic_agency.rb** - Multi-agent system with supervisor coordination
- **basic_termination.rb** - Agent with conversation termination conditions
- **workflow_agency.rb** - Sequential workflow between agents

All examples work identically across providers thanks to Bristow's universal function schema format.