# rdawn

`rdawn` is an open-source framework for Ruby, built on Ruby on Rails 8.0, designed for creating robust, **web-native AI agents**. Unlike agentic frameworks that operate as external services, `rdawn` is envisioned as the **central nervous system of a SaaS application**, allowing developers to build AI capabilities that are deeply integrated with the application's data models, business logic, and user context.

## Key Features

- **🔗 Rails-Native Integration**: Deep integration with Active Record, Active Job, and the Rails ecosystem
- **🧠 LLM Integration**: Direct OpenAI API integration with robust error handling
- **🛠️ Extensible Tool System**: Register and execute custom tools with flexible parameter handling
- **⚡ DirectHandlerTask**: Execute Ruby code directly within workflows for maximum flexibility
- **🔄 Sequential Workflows**: Robust workflow engine with conditional execution and failure handling
- **📊 Variable Resolution**: Pass data between tasks with `${...}` syntax support
- **⏰ Task Scheduling**: Built-in cron scheduling with CronTool for automated task execution
- **🔍 RAG & Web Search**: Vector store integration and real-time web search capabilities
- **📝 AI-Powered Tools**: Markdown generation, file processing, and content management
- **⚡ Real-time UI Updates**: ActionCableTool for live Turbo Stream and Action Cable broadcasts ✅ *Production-tested*
- **🛡️ Security-First Authorization**: PunditPolicyTool for permission verification and access control ✅ *Production-tested*
- **🔍 Business-Focused Querying**: ActiveRecordScopeTool for safe database queries using domain language ✅ *Production-tested*
- **📧 Professional Email Communication**: ActionMailerTool for branded emails with Rails templates ✅ *Production-ready*
- **🎯 Type Safety**: Comprehensive validation and error handling throughout

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rdawn'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rdawn

## API Key Setup

**Important**: You need an OpenAI API key to run any examples or use LLM features in rdawn.

### Option 1: Environment Variable (Recommended)

Set your OpenAI API key as an environment variable:

```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
export OPENAI_API_KEY="sk-your-actual-openai-api-key-here"

# Or add to your Rails application's .env file
OPENAI_API_KEY=sk-your-actual-openai-api-key-here

# Alternative environment variable name (also supported)
RDAWN_LLM_API_KEY=sk-your-actual-openai-api-key-here
```

### Option 2: Rails Credentials (Rails Apps)

For Rails applications, you can store the API key in encrypted credentials:

```bash
# Edit credentials
rails credentials:edit

# Add to the opened file:
openai_api_key: sk-your-actual-openai-api-key-here
```

Then configure in your initializer:

```ruby
# config/initializers/rdawn.rb
Rdawn.configure do |config|
  config.llm_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
  config.llm_model = 'gpt-4o-mini'  # or 'gpt-4', 'gpt-3.5-turbo', etc.
  config.llm_provider = 'openai'    # Currently only OpenAI is supported
end

# Register advanced tools (file search, web search, markdown, etc.)
api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
Rdawn::Tools.register_advanced_tools(api_key: api_key)
```

### Option 3: Direct Configuration

You can also pass the API key directly when initializing:

```ruby
llm_interface = Rdawn::LLMInterface.new(
  provider: :openai,
  api_key: 'sk-your-actual-openai-api-key-here',
  model: 'gpt-4o-mini'
)
```

### Supported LLM Providers

**Current Version**: Only **OpenAI** is supported with direct API integration for maximum reliability and compatibility.

**Future Versions**: OpenRouter support will be re-added in a future release to provide access to multiple LLM providers (Anthropic Claude, Google Gemini, etc.).

### Getting Your OpenAI API Key

1. Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)
5. Add billing information to your OpenAI account
6. Set usage limits if desired

**Note**: Keep your API key secure and never commit it to version control!

## Quick Start

### Basic Workflow Example

```ruby
require 'rdawn'

# Create a workflow
workflow = Rdawn::Workflow.new(workflow_id: 'example', name: 'Example Workflow')

# Add tasks
task1 = Rdawn::Task.new(task_id: '1', name: 'Initialize')
task1.next_task_id_on_success = '2'

task2 = Rdawn::Task.new(task_id: '2', name: 'Process')
workflow.add_task(task1)
workflow.add_task(task2)

# Create and run agent
llm_interface = Rdawn::LLMInterface.new(
  provider: :openai,
  api_key: ENV['OPENAI_API_KEY'],
  model: 'gpt-4o-mini'
)
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
result = agent.run(initial_input: { user_id: 123 })
```

## Task Types

### 1. DirectHandlerTask - Execute Ruby Code

Perfect for Rails integration and custom business logic:

```ruby
# Simple handler
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: '1',
  name: 'Create User',
  handler: proc do |input_data|
    # Direct Rails model interaction
    user = User.create!(
      name: input_data[:name],
      email: input_data[:email]
    )
    { user_id: user.id, created: true }
  end,
  input_data: { name: 'John', email: 'john@example.com' }
)

# Handler with workflow variables
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: '2',
  name: 'Process Data',
  handler: proc do |input_data, workflow_vars|
    user_id = workflow_vars[:user_id]
    user = User.find(user_id)
    
    # Complex business logic
    result = SomeService.new(user).process(input_data)
    { processed: true, result: result }
  end
)

# Handler with keyword arguments
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: '3',
  name: 'Send Notification',
  handler: proc do |user_id:, message:, **other_vars|
    UserMailer.notification(user_id, message).deliver_now
    { sent: true, timestamp: Time.current }
  end
)
```

### 2. LLM Tasks - AI Integration

```ruby
# Simple LLM task
task = Rdawn::Task.new(
  task_id: '1',
  name: 'Generate Content',
  is_llm_task: true,
  input_data: {
    prompt: 'Write a product description for a Ruby gem',
    model_params: { temperature: 0.7, max_tokens: 500 }
  }
)

# LLM task with dynamic prompt
task = Rdawn::Task.new(
  task_id: '2',
  name: 'Analyze Data',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this data: ${previous_task_result}',
    model_params: { temperature: 0.3 }
  }
)
```

### 3. Tool Tasks - Reusable Components

```ruby
# Register a tool
calculator = proc do |input|
  a = input[:a]
  b = input[:b]
  operation = input[:operation]
  
  result = case operation
  when 'add' then a + b
  when 'multiply' then a * b
  else 'Unknown operation'
  end
  
  { result: result, operation: operation }
end

Rdawn::ToolRegistry.register('calculator', calculator)

# Use tool in workflow
task = Rdawn::Task.new(
  task_id: '1',
  name: 'Calculate',
  tool_name: 'calculator',
  input_data: { a: 10, b: 5, operation: 'add' }
)
```

### Built-in Tools

rdawn includes powerful built-in tools for common AI agent tasks:

```ruby
# Register all built-in tools
Rdawn::Tools.register_advanced_tools(api_key: ENV['OPENAI_API_KEY'])

# Web Search
Rdawn::ToolRegistry.execute('web_search', {
  query: 'latest Ruby on Rails news',
  context_size: 'medium'
})

# Vector Store & RAG
Rdawn::ToolRegistry.execute('vector_store_create', {
  name: 'Knowledge Base',
  file_ids: ['file-123']
})

Rdawn::ToolRegistry.execute('file_search', {
  query: 'How to deploy Rails applications?',
  vector_store_ids: ['vs-abc123']
})

# AI-Powered Markdown
Rdawn::ToolRegistry.execute('markdown_generate', {
  prompt: 'Create a technical blog post about Ruby on Rails',
  style: 'technical',
  length: 'medium'
})

# Task Scheduling with CronTool
Rdawn::ToolRegistry.execute('cron_schedule_task', {
  name: 'daily_report',
  cron_expression: '0 9 * * *',  # Daily at 9 AM
  tool_name: 'web_search',
  input_data: { query: 'daily tech news' }
})

# List scheduled jobs
jobs = Rdawn::ToolRegistry.execute('cron_list_jobs', {})
puts "Active jobs: #{jobs[:active_jobs]}"
```

## Configuration

### LLM Configuration

Once your API key is set up (see [API Key Setup](#api-key-setup) above), you can configure the LLM interface:

```ruby
# Using environment variables (API key auto-detected)
llm_interface = Rdawn::LLMInterface.new

# Or explicit configuration
llm_interface = Rdawn::LLMInterface.new(
  provider: :open_router,
  api_key: ENV['OPENAI_API_KEY'],
  model: 'anthropic/claude-3.5-sonnet'
)
```

### Rails Integration

Create `config/initializers/rdawn.rb`:

```ruby
# config/initializers/rdawn.rb
Rdawn.configure do |config|
  config.llm_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
  config.llm_model = 'gpt-4o-mini'  # or 'gpt-4', 'gpt-3.5-turbo'
  config.llm_provider = 'openai'    # Currently only OpenAI supported
  config.default_model_params = {
    temperature: 0.7,
    max_tokens: 1000
  }
end

# Register advanced tools (optional but recommended)
api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
Rdawn::Tools.register_advanced_tools(api_key: api_key)
```

**Rails Generator (Recommended):**

```bash
# Generate Rails integration files
rails generate rdawn:install
```

This creates the initializer, workflow directories, and background job classes.

## Advanced Features

### Variable Resolution

Pass data between tasks using `${...}` syntax:

```ruby
task1 = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: '1',
  name: 'Get User',
  handler: proc { |input| { user_id: 123, name: 'John' } }
)

task2 = Rdawn::Task.new(
  task_id: '2',
  name: 'Generate Email',
  is_llm_task: true,
  input_data: {
    prompt: 'Write a welcome email for user ${user_id} named ${name}'
  }
)
```

### Conditional Execution

```ruby
task = Rdawn::Task.new(task_id: '1', name: 'Process')
task.next_task_id_on_success = '2'  # Normal flow
task.next_task_id_on_failure = '3'  # Error handling
task.condition = proc { |workflow_vars| workflow_vars[:user_type] == 'premium' }
```

### Error Handling

```ruby
begin
  result = agent.run(initial_input: { user_id: 123 })
rescue Rdawn::Errors::TaskExecutionError => e
  Rails.logger.error "Task failed: #{e.message}"
rescue Rdawn::Errors::ConfigurationError => e
  Rails.logger.error "Configuration error: #{e.message}"
end
```

## Rails Integration Examples

### User Onboarding Workflow

```ruby
class UserOnboardingWorkflow
  def self.create_workflow(user)
    workflow = Rdawn::Workflow.new(
      workflow_id: "onboarding_#{user.id}",
      name: 'User Onboarding'
    )
    
    # Step 1: Send welcome email
    welcome_task = Rdawn::Tasks::DirectHandlerTask.new(
      task_id: '1',
      name: 'Send Welcome Email',
      handler: proc do |input_data|
        user = User.find(input_data[:user_id])
        UserMailer.welcome(user).deliver_now
        { email_sent: true, user_name: user.name }
      end,
      input_data: { user_id: user.id }
    )
    welcome_task.next_task_id_on_success = '2'
    
    # Step 2: Generate personalized content
    content_task = Rdawn::Task.new(
      task_id: '2',
      name: 'Generate Personalized Content',
      is_llm_task: true,
      input_data: {
        prompt: 'Create personalized onboarding content for ${user_name}'
      }
    )
    content_task.next_task_id_on_success = '3'
    
    # Step 3: Create user profile
    profile_task = Rdawn::Tasks::DirectHandlerTask.new(
      task_id: '3',
      name: 'Create Profile',
      handler: proc do |input_data, workflow_vars|
        user = User.find(input_data[:user_id])
        content = workflow_vars[:llm_response]
        
        user.profile.update!(
          onboarding_content: content,
          onboarding_completed: true
        )
        
        { profile_created: true }
      end,
      input_data: { user_id: user.id }
    )
    
    workflow.add_task(welcome_task)
    workflow.add_task(content_task)
    workflow.add_task(profile_task)
    
    workflow
  end
end

# Usage
user = User.find(123)
workflow = UserOnboardingWorkflow.create_workflow(user)
llm_interface = Rdawn::LLMInterface.new
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
result = agent.run
```

### Real-time UI Updates with ActionCableTool ✅ *Production-Tested*

Enable live, real-time UI updates using Hotwire Turbo Streams. **Successfully tested in Fat Free CRM** with AI-powered lead analysis workflows:

```ruby
# Real-time project analysis workflow
analysis_workflow = Rdawn::Workflow.new(
  workflow_id: 'real_time_analysis',
  name: 'Live Project Analysis'
)

# Step 1: Show loading state
loading_task = Rdawn::Task.new(
  task_id: '1',
  name: 'Show Loading',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: project,
    target: 'analysis_status',
    turbo_action: 'replace',
    content: '<div class="animate-pulse">🔍 AI Analysis in progress...</div>'
  }
)
loading_task.next_task_id_on_success = '2'

# Step 2: Perform analysis
ai_task = Rdawn::Task.new(
  task_id: '2',
  name: 'AI Analysis',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this project: ${project.description}',
    model_params: { max_tokens: 500 }
  }
)
ai_task.next_task_id_on_success = '3'

# Step 3: Update UI with results
result_task = Rdawn::Task.new(
  task_id: '3',
  name: 'Show Results',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: project,
    target: 'analysis_results',
    turbo_action: 'replace',
    partial: 'projects/analysis_result',
    locals: {
      analysis: '${llm_response}',
      completed_at: Time.current
    }
  }
)

# Users see live updates without page refresh!
```

**Rails View Setup:**
```erb
<!-- app/views/projects/show.html.erb -->
<%= turbo_stream_from @project %>

<div id="analysis_status">
  <!-- Loading states appear here -->
</div>

<div id="analysis_results">
  <!-- Results appear here in real-time -->
</div>
```

### Background Job Integration

```ruby
class WorkflowJob < ApplicationJob
  queue_as :default
  
  def perform(workflow_class, workflow_params)
    workflow = workflow_class.constantize.create_workflow(**workflow_params)
    llm_interface = Rdawn::LLMInterface.new
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
    
    result = agent.run
    
    # Broadcast completion via Action Cable
    ActionCable.server.broadcast(
      "workflow_#{workflow.workflow_id}",
      { status: 'completed', result: result.to_h }
    )
  end
end

# Enqueue workflow
WorkflowJob.perform_later('UserOnboardingWorkflow', { user_id: 123 })
```

## API Reference

### Core Classes

#### `Rdawn::Workflow`
- `workflow_id`: Unique identifier
- `name`: Human-readable name
- `status`: Current status (`:pending`, `:running`, `:completed`)
- `tasks`: Hash of tasks by task_id
- `variables`: Workflow-level variables
- `add_task(task)`: Add a task to the workflow
- `get_task(task_id)`: Retrieve a task by ID

#### `Rdawn::Task`
- `task_id`: Unique identifier
- `name`: Human-readable name
- `status`: Current status
- `input_data`: Input data for the task
- `output_data`: Output data from the task
- `is_llm_task`: Boolean flag for LLM tasks
- `tool_name`: Name of tool to execute
- `next_task_id_on_success`: Next task if successful
- `next_task_id_on_failure`: Next task if failed

#### `Rdawn::Tasks::DirectHandlerTask`
- `handler`: Proc, lambda, or callable object
- Supports 0, 1, 2, or keyword parameters
- Access to input data and workflow variables

#### `Rdawn::Agent`
- `initialize(workflow:, llm_interface:)`: Create agent
- `run(initial_input: {})`: Execute workflow

#### `Rdawn::LLMInterface`
- `initialize(provider:, api_key:, model:)`: Create interface
- `execute_llm_call(prompt:, model_params:)`: Execute LLM call

#### `Rdawn::ToolRegistry`
- `register(name, tool_object)`: Register a tool
- `execute(name, input_data)`: Execute a tool
- `registered_tools`: List all registered tools

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/rdawn/task_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Development Setup

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run with auto-reload during development
bundle exec guard

# Generate documentation
bundle exec yard
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/emezac/rdawn.

### Development Process

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Create a Pull Request

### Code Style

This project uses RuboCop for code style enforcement. Run `bundle exec rubocop` to check your code.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Roadmap

- **v0.2.0**: Variable resolution with `${...}` syntax
- **v0.3.0**: Rails generators and improved ActiveJob integration
- **v0.4.0**: Action Cable real-time updates
- **v0.5.0**: Multiple LLM provider support
- **v1.0.0**: Production-ready Rails integration with full documentation

## Documentation

- [Tools Guide](docs/TOOLS.md) - Comprehensive guide to built-in and custom tools
- [CronTool Documentation](docs/CRON_TOOL.md) - Complete task scheduling guide
- [Advanced Features](docs/ADVANCED_FEATURES.md) - RAG, Web Search, and scheduling features
- [Workflows Guide](docs/WORKFLOWS.md) - Building complex AI workflows

## Examples

- [Simple Example](../examples/simple_example.rb) - Basic workflow demonstration
- [Vector Store Example](../examples/vector_store_example.rb) - RAG implementation
- [Web Search Example](../examples/web_search_example.rb) - Real-time web search
- [Markdown Example](../examples/markdown_example.rb) - AI-powered content generation
- [Cron Example](../examples/cron_example.rb) - Task scheduling with CronTool
- [Legal Workflow Example](../examples/legal_review_workflow_example.rb) - Complex business workflow

## Support

- [GitHub Issues](https://github.com/emezac/rdawn/issues)
- [Documentation](https://github.com/emezac/rdawn/wiki)
- [Examples](https://github.com/emezac/rdawn/tree/main/examples)
