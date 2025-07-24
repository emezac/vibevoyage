# rdawn Documentation

This directory contains comprehensive documentation for the rdawn framework.

## Getting Started

### [INSTALL.md](INSTALL.md)
Complete installation guide for rdawn. Covers:
- System requirements and dependencies
- Installation methods (RubyGems, Bundler, source)
- API key setup and configuration
- Verification steps and troubleshooting
- Rails integration and advanced setup
- **[OpenAI Integration Update](OPENAI_INTEGRATION_UPDATE.md)** - Latest working configuration
- **[ActionCableTool](tools/action_cable_tool.md)** - Real-time UI updates with Turbo Streams ✅ *Production-tested*
- **[PunditPolicyTool](tools/pundit_policy_tool.md)** - Security-first authorization with Pundit integration ✅ *Production-tested*
- **[ActiveRecordScopeTool](tools/active_record_scope_tool.md)** - Business-focused database querying with secure scopes ✅ *Production-tested*
- **[ActionMailerTool](tools/action_mailer_tool.md)** - Professional email communication with Rails templates ✅ *Production-ready*

## Core Documentation

### [TOOLS.md](TOOLS.md)
Complete guide to using and creating tools in rdawn. Covers:
- Built-in tools (Vector Store, Web Search, Markdown, Cron)
- Custom tool creation
- Tool registry system
- Best practices and patterns

### [CRON_TOOL.md](CRON_TOOL.md)
Comprehensive guide to the CronTool for task scheduling. Includes:
- Cron expression scheduling
- One-time and recurring tasks
- Tool integration and workflow scheduling
- API reference and examples
- Advanced features and best practices

### [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)
Documentation for advanced rdawn capabilities:
- RAG (Retrieval-Augmented Generation) with vector stores
- Real-time web search integration
- Task scheduling with CronTool
- Enhanced LLM interface features

### [WORKFLOWS.md](WORKFLOWS.md)
Guide to building and managing complex AI workflows:
- Workflow design patterns
- Task orchestration
- Variable resolution
- Error handling strategies

## Tool-Specific Documentation

### [WEB_SEARCH_TOOL.md](WEB_SEARCH_TOOL.md)
Detailed documentation for web search capabilities:
- OpenAI web search integration
- Context sizing and location-based search
- Citation handling and output formats

### [MARKDOWN_TOOL.md](MARKDOWN_TOOL.md)
AI-powered markdown generation and editing:
- Content generation with different styles
- Intelligent editing and formatting
- Template creation and validation
- Marksmith integration for Rails

## Integration Guides

### [RAILS_INTEGRATION.md](RAILS_INTEGRATION.md)
Rails-specific integration patterns and examples:
- ActiveRecord integration
- Rails generators and helpers
- Background job integration

### [MCP_INTEGRATION.md](MCP_INTEGRATION.md)
Model Context Protocol integration:
- MCP server setup and configuration
- Tool registration and execution
- Advanced MCP patterns

## Feature Documentation

### [DIRECT_HANDLERS.md](DIRECT_HANDLERS.md)
DirectHandlerTask implementation and usage:
- Custom business logic execution
- Handler patterns and best practices
- Integration with workflows

### [FILE_SEARCH.md](FILE_SEARCH.md)
Vector store and file search functionality:
- File upload and indexing
- Semantic search capabilities
- RAG implementation patterns

### [CONTEXT_AWARE_WORKFLOW_IMPROVEMENTS.md](CONTEXT_AWARE_WORKFLOW_IMPROVEMENTS.md)
Enhancements to workflow context and variable resolution:
- Improved task output handling
- Enhanced variable resolution
- Complex data structure navigation

## Planning and Design

### [PRD_RDAWN.md](PRD_RDAWN.md)
Product Requirements Document for rdawn:
- Project vision and goals
- Feature specifications
- Technical requirements

### [PHASE_4_SUMMARY.md](PHASE_4_SUMMARY.md)
Latest development phase summary:
- Recent implementations
- Feature completions
- Next steps

## Examples and Templates

### [CONTEXT-AWARE-WORKFLOW-EXAMPLE-TEMPLATE.txt](CONTEXT-AWARE-WORKFLOW-EXAMPLE-TEMPLATE.txt)
Template for building context-aware workflows:
- Legal review workflow example
- Long-term memory integration
- Multi-stage processing patterns

## Quick Reference

### Key Documentation by Use Case

**Getting Started:**
- [INSTALL.md](INSTALL.md) - Installation and setup guide
- [README.md](../rdawn/README.md) - Main framework overview
- [TOOLS.md](TOOLS.md) - Tool system basics

**Building Workflows:**
- [WORKFLOWS.md](WORKFLOWS.md) - Workflow patterns
- [DIRECT_HANDLERS.md](DIRECT_HANDLERS.md) - Custom logic

**AI Features:**
- [WEB_SEARCH_TOOL.md](WEB_SEARCH_TOOL.md) - Real-time search
- [MARKDOWN_TOOL.md](MARKDOWN_TOOL.md) - Content generation
- [FILE_SEARCH.md](FILE_SEARCH.md) - RAG implementation

**Automation:**
- [CRON_TOOL.md](CRON_TOOL.md) - Task scheduling
- [MCP_INTEGRATION.md](MCP_INTEGRATION.md) - External integrations

**Rails Integration:**
- [RAILS_INTEGRATION.md](RAILS_INTEGRATION.md) - Rails patterns
- [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md) - Production features

### Examples Directory

The `../examples/` directory contains working code examples:
- `simple_example.rb` - Basic workflow
- `vector_store_example.rb` - RAG demonstration
- `web_search_example.rb` - Web search integration
- `markdown_example.rb` - AI content generation
- `cron_example.rb` - Task scheduling
- `legal_review_workflow_example.rb` - Complex business workflow

### Documentation Standards

All documentation follows these standards:
- Clear examples with working code
- Comprehensive API references
- Best practices and patterns
- Error handling guidance
- Real-world use cases

For the most up-to-date information, always refer to the specific documentation file and the examples directory. 