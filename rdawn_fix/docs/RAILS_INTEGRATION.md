# Rails Integration Guide

This guide explains how to integrate `rdawn` into your Rails application for building powerful, Rails-native AI agents.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Active Job Integration](#active-job-integration)
- [Workflow Handlers](#workflow-handlers)
- [Usage Examples](#usage-examples)
- [Security Considerations](#security-considerations)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

## Installation

### 1. Add to Gemfile

```ruby
# Gemfile
gem 'rdawn'
```

### 2. Install the gem

```bash
bundle install
```

### 3. Run the generator

```bash
rails generate rdawn:install
```

This creates:
- `config/initializers/rdawn.rb` - Configuration file
- `app/workflows/` - Directory for workflow definitions
- `app/workflows/handlers/` - Directory for workflow handlers

## Configuration

### Basic Configuration

Edit `config/initializers/rdawn.rb`:

```ruby
# config/initializers/rdawn.rb
require 'rdawn/rails'

# Configure rdawn
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

# Configure Rails-specific settings
Rdawn::Rails.configure do |config|
  config.default_queue_adapter = :async  # or :sidekiq, :resque, etc.
  config.default_queue_name = :rdawn
  config.enable_active_job_integration = true
end

# Configure rdawn
Rdawn.configure do |config|
  # LLM Configuration
  config.llm_api_key = ENV['RDAWN_LLM_API_KEY'] || ENV['OPENAI_API_KEY']
  config.llm_model = ENV['RDAWN_LLM_MODEL'] || 'gpt-4o-mini'
  config.llm_provider = ENV['RDAWN_LLM_PROVIDER'] || 'openrouter'
  
  # Default model parameters
  config.default_model_params = {
    temperature: 0.7,
    max_tokens: 1000
  }
end

# Configure Rails-specific settings
Rdawn::Rails.configure do |config|
  config.default_queue_adapter = :sidekiq  # or :async, :resque, etc.
  config.default_queue_name = :rdawn
  config.enable_active_job_integration = true
end
```

### Environment Variables

Set up your environment variables:

```bash
# .env or environment
RDAWN_LLM_API_KEY=your_api_key_here
RDAWN_LLM_MODEL=gpt-4o-mini
RDAWN_LLM_PROVIDER=openrouter
```

## Active Job Integration

### Background Workflow Execution

Execute workflows in the background using Active Job:

```ruby
# In your controller or service
class WorkflowController < ApplicationController
  def create_user_onboarding
    workflow_data = {
      workflow_id: 'user_onboarding',
      name: 'User Onboarding Workflow',
      tasks: {
        'welcome_task' => {
          type: 'direct_handler',
          name: 'Send Welcome Email',
          handler: 'UserOnboarding#send_welcome_email',
          input_data: { user_id: params[:user_id] },
          next_task_id_on_success: 'setup_task'
        },
        'setup_task' => {
          type: 'direct_handler',
          name: 'Setup User Account',
          handler: 'UserOnboarding#setup_account',
          input_data: { user_id: params[:user_id] }
        }
      }
    }
    
    # Execute in background
    Rdawn::Rails::WorkflowJob.run_workflow_later(
      workflow_data: workflow_data,
      llm_config: { api_key: ENV['RDAWN_LLM_API_KEY'] },
      initial_input: { user_id: params[:user_id] },
      user_context: { current_user_id: current_user.id }
    )
    
    render json: { message: 'Workflow started' }
  end
end
```

### Immediate Execution (for testing)

```ruby
# For testing or immediate execution
result = Rdawn::Rails::WorkflowJob.run_workflow_now(
  workflow_data: workflow_data,
  llm_config: { api_key: ENV['RDAWN_LLM_API_KEY'] },
  initial_input: { user_id: user.id }
)
```

## Workflow Handlers

### Creating Workflow Handlers

Create handlers in `app/workflows/handlers/`:

```ruby
# app/workflows/handlers/user_onboarding.rb
class UserOnboarding
  def send_welcome_email(input_data, workflow_variables)
    user = User.find(input_data['user_id'])
    UserMailer.welcome_email(user).deliver_now
    
    {
      success: true,
      user: user.attributes,
      email_sent: true
    }
  end
  
  def setup_account(input_data, workflow_variables)
    user = User.find(input_data['user_id'])
    user.update!(
      onboarded: true,
      setup_completed_at: Time.current
    )
    
    {
      success: true,
      user: user.attributes,
      setup_completed: true
    }
  end
end
```

### Using Active Record Models

Handlers have full access to Active Record models:

```ruby
# app/workflows/handlers/project_management.rb
class ProjectManagement
  def create_project(input_data, workflow_variables)
    user = User.find(input_data['user_id'])
    
    project = user.projects.create!(
      name: input_data['project_name'],
      description: input_data['project_description']
    )
    
    # Create default tasks
    project.tasks.create!([
      { title: 'Setup project', status: 'pending' },
      { title: 'Review requirements', status: 'pending' },
      { title: 'Start development', status: 'pending' }
    ])
    
    {
      success: true,
      project: project.attributes,
      tasks_created: project.tasks.count
    }
  end
  
  def notify_team(input_data, workflow_variables)
    project = Project.find(input_data['project_id'])
    
    project.team_members.each do |member|
      ProjectMailer.project_created(member, project).deliver_now
    end
    
    {
      success: true,
      notifications_sent: project.team_members.count
    }
  end
end
```

### Handler Security

For security, handlers in Rails context must be string references:

```ruby
# Safe - references existing class methods
{
  type: 'direct_handler',
  handler: 'UserOnboarding#send_welcome_email'
}

# Also safe - class with call method
{
  type: 'direct_handler',
  handler: 'UserOnboarding'
}

# Unsafe - raw proc/lambda (rejected in Rails context)
{
  type: 'direct_handler',
  handler: proc { |input| User.destroy_all }  # This will raise an error
}
```

## Usage Examples

### User Onboarding Workflow

```ruby
# app/workflows/user_onboarding_workflow.rb
class UserOnboardingWorkflow
  def self.build_workflow(user_id)
    {
      workflow_id: "user_onboarding_#{user_id}",
      name: 'User Onboarding',
      tasks: {
        'send_welcome' => {
          type: 'direct_handler',
          name: 'Send Welcome Email',
          handler: 'UserOnboarding#send_welcome_email',
          input_data: { user_id: user_id },
          next_task_id_on_success: 'ai_personalization'
        },
        'ai_personalization' => {
          type: 'llm',
          name: 'Generate Personalized Content',
          input_data: {
            prompt: 'Generate personalized onboarding content for user ${user.name} with interests: ${user.interests}',
            model_params: { temperature: 0.8 }
          },
          next_task_id_on_success: 'save_content'
        },
        'save_content' => {
          type: 'direct_handler',
          name: 'Save Personalized Content',
          handler: 'UserOnboarding#save_personalized_content',
          input_data: { user_id: user_id, content: '${ai_personalization.llm_response}' }
        }
      }
    }
  end
  
  def self.start_for_user(user)
    workflow_data = build_workflow(user.id)
    
    Rdawn::Rails::WorkflowJob.run_workflow_later(
      workflow_data: workflow_data,
      llm_config: {
        api_key: ENV['RDAWN_LLM_API_KEY'],
        model: 'gpt-4o-mini'
      },
      initial_input: { user_id: user.id },
      user_context: { 
        user: user.attributes,
        environment: Rails.env
      }
    )
  end
end
```

### E-commerce Order Processing

```ruby
# app/workflows/order_processing_workflow.rb
class OrderProcessingWorkflow
  def self.process_order(order_id)
    workflow_data = {
      workflow_id: "order_processing_#{order_id}",
      name: 'Order Processing',
      tasks: {
        'validate_order' => {
          type: 'direct_handler',
          name: 'Validate Order',
          handler: 'OrderProcessing#validate_order',
          input_data: { order_id: order_id },
          next_task_id_on_success: 'check_inventory',
          next_task_id_on_failure: 'send_error_notification'
        },
        'check_inventory' => {
          type: 'direct_handler',
          name: 'Check Inventory',
          handler: 'OrderProcessing#check_inventory',
          input_data: { order_id: order_id },
          next_task_id_on_success: 'process_payment',
          next_task_id_on_failure: 'handle_out_of_stock'
        },
        'process_payment' => {
          type: 'direct_handler',
          name: 'Process Payment',
          handler: 'OrderProcessing#process_payment',
          input_data: { order_id: order_id },
          next_task_id_on_success: 'fulfill_order',
          next_task_id_on_failure: 'handle_payment_failure'
        },
        'fulfill_order' => {
          type: 'direct_handler',
          name: 'Fulfill Order',
          handler: 'OrderProcessing#fulfill_order',
          input_data: { order_id: order_id },
          next_task_id_on_success: 'send_confirmation'
        },
        'send_confirmation' => {
          type: 'direct_handler',
          name: 'Send Confirmation',
          handler: 'OrderProcessing#send_confirmation',
          input_data: { order_id: order_id }
        }
      }
    }
    
    Rdawn::Rails::WorkflowJob.run_workflow_later(
      workflow_data: workflow_data,
      llm_config: { api_key: ENV['RDAWN_LLM_API_KEY'] },
      initial_input: { order_id: order_id }
    )
  end
end
```

## Security Considerations

### 1. Handler Validation

- Only string references to existing classes are allowed
- No raw code execution in production
- All handlers must be defined in your Rails application

### 2. Input Sanitization

```ruby
class SecureHandler
  def process_user_input(input_data, workflow_variables)
    # Always validate and sanitize input
    user_id = input_data['user_id'].to_i
    raise ArgumentError, 'Invalid user ID' unless user_id > 0
    
    user = User.find(user_id)
    # ... safe processing
  end
end
```

### 3. Authorization

```ruby
class AuthorizedHandler
  def process_data(input_data, workflow_variables)
    current_user_id = workflow_variables['current_user_id']
    current_user = User.find(current_user_id)
    
    # Check permissions
    unless current_user.can_access_resource?(input_data['resource_id'])
      raise SecurityError, 'Unauthorized access'
    end
    
    # ... proceed with processing
  end
end
```

## Performance Tips

### 1. Database Optimization

```ruby
# Use includes to avoid N+1 queries
def process_user_data(input_data, workflow_variables)
  user = User.includes(:profile, :preferences).find(input_data['user_id'])
  # ... process with related data
end
```

### 2. Caching

```ruby
def expensive_operation(input_data, workflow_variables)
  cache_key = "workflow_#{input_data['user_id']}_#{input_data['operation']}"
  
  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    # ... expensive operation
  end
end
```

### 3. Queue Management

```ruby
# config/initializers/rdawn.rb
Rdawn::Rails.configure do |config|
  # Use different queues for different priorities
  config.default_queue_name = :rdawn_default
  
  # Configure in your job classes
  class HighPriorityWorkflowJob < Rdawn::Rails::WorkflowJob
    queue_as :rdawn_high_priority
  end
end
```

## Troubleshooting

### Common Issues

1. **Handler Not Found Error**
   ```
   Invalid handler reference: UserOnboarding#nonexistent_method
   ```
   - Ensure the handler class and method exist
   - Check the handler reference syntax

2. **Variable Resolution Error**
   ```
   Cannot resolve 'user.name' in path 'user.name'
   ```
   - Verify the variable exists in the workflow context
   - Check the variable path syntax

3. **LLM Configuration Error**
   ```
   API key is missing or invalid
   ```
   - Set the correct environment variables
   - Verify API key validity

### Debugging

Enable detailed logging:

```ruby
# config/initializers/rdawn.rb
Rails.logger.level = :debug

# In your handlers
def debug_handler(input_data, workflow_variables)
  Rails.logger.debug "Input: #{input_data}"
  Rails.logger.debug "Variables: #{workflow_variables}"
  # ... processing
end
```

### Testing

Create test helpers:

```ruby
# spec/support/workflow_helpers.rb
module WorkflowHelpers
  def run_workflow_synchronously(workflow_data, initial_input: {})
    Rdawn::Rails::WorkflowJob.run_workflow_now(
      workflow_data: workflow_data,
      llm_config: { api_key: 'test_key' },
      initial_input: initial_input
    )
  end
end
```

For more advanced usage and examples, see the main rdawn documentation. 