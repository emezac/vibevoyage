# Workflows in rdawn

This guide explains how to create and use workflows in the rdawn framework.

## Table of Contents

- [Overview](#overview)
- [Basic Workflow Structure](#basic-workflow-structure)
- [Creating Workflows](#creating-workflows)
- [Task Types](#task-types)
- [Variable Resolution](#variable-resolution)
- [Conditional Execution](#conditional-execution)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

Workflows in rdawn are the core orchestration mechanism that allows you to chain together different types of tasks to create complex AI-powered processes. A workflow consists of multiple tasks that can be executed sequentially or conditionally based on the results of previous tasks.

## Basic Workflow Structure

```ruby
workflow = Rdawn::Workflow.new(
  workflow_id: 'my_workflow',
  name: 'My Example Workflow'
)

# Add tasks to the workflow
workflow.add_task(task1)
workflow.add_task(task2)
workflow.add_task(task3)

# Execute the workflow
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
result = agent.run(initial_input: { user_id: 123 })
```

## Creating Workflows

### 1. Initialize a Workflow

```ruby
workflow = Rdawn::Workflow.new(
  workflow_id: 'user_onboarding',
  name: 'User Onboarding Process'
)
```

### 2. Add Tasks

Tasks are added to workflows and linked together using success and failure paths:

```ruby
# Create tasks
task1 = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'validate_user',
  name: 'Validate User Data',
  handler: proc do |input_data|
    # Validation logic
    { valid: true, user_id: input_data[:user_id] }
  end
)

task2 = Rdawn::Task.new(
  task_id: 'generate_welcome',
  name: 'Generate Welcome Message',
  is_llm_task: true,
  input_data: {
    prompt: 'Generate a welcome message for user ${user_id}',
    model_params: { temperature: 0.7 }
  }
)

# Link tasks
task1.next_task_id_on_success = 'generate_welcome'
task1.next_task_id_on_failure = 'handle_error'

# Add to workflow
workflow.add_task(task1)
workflow.add_task(task2)
```

### 3. Execute the Workflow

```ruby
# Create LLM interface
llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])

# Create agent and run
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
result = agent.run(initial_input: { user_id: 123, name: 'John Doe' })

# Access results
puts result.status           # :completed
puts result.tasks.count      # Number of executed tasks
puts result.variables        # Workflow variables
```

## Task Types

### DirectHandlerTask

Execute Ruby code directly within the workflow:

```ruby
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'process_data',
  name: 'Process User Data',
  handler: proc do |input_data, workflow_vars|
    user = User.find(input_data[:user_id])
    user.update!(last_login: Time.now)
    
    { user: user.attributes, updated: true }
  end
)
```

### LLM Task

Interact with AI models:

```ruby
task = Rdawn::Task.new(
  task_id: 'analyze_sentiment',
  name: 'Analyze Sentiment',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze the sentiment of this text: ${user_message}',
    model_params: { temperature: 0.3, max_tokens: 100 }
  }
)
```

### Tool Task

Execute registered tools:

```ruby
task = Rdawn::Task.new(
  task_id: 'format_text',
  name: 'Format Text',
  tool_name: 'text_formatter',
  input_data: {
    text: '${raw_text}',
    format: 'uppercase'
  }
)
```

## Variable Resolution

rdawn supports dynamic variable resolution using the `${variable_name}` syntax:

### Basic Variables

```ruby
task1 = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'get_user',
  name: 'Get User',
  handler: proc { |input| { user_name: 'John', user_id: 123 } }
)

task2 = Rdawn::Task.new(
  task_id: 'greet_user',
  name: 'Greet User',
  is_llm_task: true,
  input_data: {
    prompt: 'Say hello to ${user_name} with ID ${user_id}'
  }
)
```

### Nested Variables

```ruby
task1 = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'get_user_data',
  name: 'Get User Data',
  handler: proc do |input|
    {
      user: {
        profile: { name: 'John', age: 30 },
        preferences: { theme: 'dark' }
      }
    }
  end
)

task2 = Rdawn::Task.new(
  task_id: 'use_nested_data',
  name: 'Use Nested Data',
  is_llm_task: true,
  input_data: {
    prompt: 'User ${user.profile.name} prefers ${user.preferences.theme} theme'
  }
)
```

### Initial Input Variables

Variables from the initial workflow input are available throughout:

```ruby
# Run with initial input
agent.run(initial_input: { company_name: 'Acme Corp', user_type: 'premium' })

# Use in any task
task = Rdawn::Task.new(
  task_id: 'welcome',
  name: 'Welcome Message',
  is_llm_task: true,
  input_data: {
    prompt: 'Welcome to ${company_name}! You are a ${user_type} user.'
  }
)
```

## Conditional Execution

### Using Conditions

Tasks can be conditionally executed based on workflow variables:

```ruby
premium_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'premium_features',
  name: 'Enable Premium Features',
  handler: proc { |input| { premium_enabled: true } }
)

# Set condition after task creation
premium_task.condition = proc { |workflow_vars| 
  workflow_vars[:user_type] == 'premium' 
}
```

### Conditional Branching

```ruby
validation_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'validate',
  name: 'Validate Data',
  handler: proc do |input_data|
    valid = input_data[:email].include?('@')
    { valid: valid, email: input_data[:email] }
  end
)

# Different paths based on validation result
validation_task.next_task_id_on_success = 'send_welcome'
validation_task.next_task_id_on_failure = 'request_valid_email'
```

## Error Handling

### Task-Level Error Handling

```ruby
risky_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'risky_operation',
  name: 'Risky Operation',
  handler: proc do |input_data|
    if input_data[:simulate_error]
      raise StandardError, 'Something went wrong'
    end
    { success: true }
  end
)

# Define error path
risky_task.next_task_id_on_failure = 'error_handler'

error_handler = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'error_handler',
  name: 'Handle Error',
  handler: proc do |input_data|
    { error_handled: true, fallback_result: 'default_value' }
  end
)
```

### Workflow-Level Error Handling

```ruby
begin
  result = agent.run(initial_input: { user_id: 123 })
  
  if result.status == :completed
    puts "Workflow completed successfully"
  else
    puts "Workflow failed or was interrupted"
  end
rescue Rdawn::Errors::TaskExecutionError => e
  puts "Task execution failed: #{e.message}"
rescue Rdawn::Errors::ConfigurationError => e
  puts "Configuration error: #{e.message}"
end
```

## Best Practices

### 1. Use Descriptive Task IDs and Names

```ruby
# Good
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'validate_user_email',
  name: 'Validate User Email Address',
  handler: email_validator
)

# Avoid
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 't1',
  name: 'Task 1',
  handler: some_proc
)
```

### 2. Keep Handlers Simple and Focused

```ruby
# Good - focused on one responsibility
email_validator = proc do |input_data|
  email = input_data[:email]
  valid = email.match?(/\A[^@\s]+@[^@\s]+\z/)
  { valid: valid, email: email }
end

# Avoid - doing too much in one handler
complex_handler = proc do |input_data|
  # Validation, database updates, email sending, etc.
  # This should be split into multiple tasks
end
```

### 3. Use Meaningful Variable Names

```ruby
# Good
task = Rdawn::Task.new(
  task_id: 'generate_report',
  name: 'Generate Monthly Report',
  is_llm_task: true,
  input_data: {
    prompt: 'Generate a monthly report for ${company_name} with data: ${monthly_metrics}'
  }
)

# Avoid
task = Rdawn::Task.new(
  task_id: 'gen_rep',
  name: 'Gen Rep',
  is_llm_task: true,
  input_data: {
    prompt: 'Generate report for ${x} with ${y}'
  }
)
```

### 4. Plan Your Workflow Structure

```ruby
# Example: User onboarding workflow structure
workflow_structure = {
  'validate_user' => {
    success: 'create_profile',
    failure: 'send_validation_error'
  },
  'create_profile' => {
    success: 'generate_welcome_message',
    failure: 'handle_profile_error'
  },
  'generate_welcome_message' => {
    success: 'send_welcome_email',
    failure: 'send_default_welcome'
  },
  'send_welcome_email' => {
    success: 'complete_onboarding',
    failure: 'log_email_error'
  }
}
```

### 5. Use Proper Error Handling

```ruby
# Always define failure paths for critical tasks
critical_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'critical_operation',
  name: 'Critical Operation',
  handler: critical_handler
)

critical_task.next_task_id_on_success = 'continue_workflow'
critical_task.next_task_id_on_failure = 'critical_error_handler'
critical_task.max_retries = 3
```

### 6. Test Your Workflows

```ruby
# Use integration tests for workflows
RSpec.describe 'UserOnboardingWorkflow' do
  it 'completes successfully with valid input' do
    workflow = create_user_onboarding_workflow
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm)
    
    result = agent.run(initial_input: { 
      user_id: 123, 
      email: 'user@example.com' 
    })
    
    expect(result.status).to eq(:completed)
    expect(result.tasks['send_welcome_email'].status).to eq(:completed)
  end
end
```

## Advanced Patterns

### Parallel Task Execution (Future Feature)

While rdawn currently executes tasks sequentially, you can design workflows to handle parallel-like operations:

```ruby
# Current approach: Sequential with conditional execution
workflow = Rdawn::Workflow.new(workflow_id: 'parallel_sim', name: 'Parallel Simulation')

# Task 1: Dispatch work
dispatch_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'dispatch',
  name: 'Dispatch Work',
  handler: proc do |input_data|
    {
      task_a_needed: true,
      task_b_needed: true,
      dispatched_at: Time.now
    }
  end
)

# Tasks A and B (executed based on conditions)
task_a = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'task_a',
  name: 'Task A',
  handler: proc { |input| { result_a: 'completed' } }
)
task_a.condition = proc { |vars| vars[:task_a_needed] }

task_b = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'task_b', 
  name: 'Task B',
  handler: proc { |input| { result_b: 'completed' } }
)
task_b.condition = proc { |vars| vars[:task_b_needed] }

# Collect results
collect_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'collect',
  name: 'Collect Results',
  handler: proc do |input_data, workflow_vars|
    {
      results: {
        a: workflow_vars[:result_a],
        b: workflow_vars[:result_b]
      }
    }
  end
)

# Link tasks
dispatch_task.next_task_id_on_success = 'task_a'
task_a.next_task_id_on_success = 'task_b'
task_b.next_task_id_on_success = 'collect'
```

### Dynamic Workflow Generation

```ruby
def create_dynamic_workflow(steps)
  workflow = Rdawn::Workflow.new(
    workflow_id: "dynamic_#{Time.now.to_i}",
    name: 'Dynamic Workflow'
  )
  
  steps.each_with_index do |step, index|
    task = Rdawn::Tasks::DirectHandlerTask.new(
      task_id: "step_#{index}",
      name: step[:name],
      handler: step[:handler]
    )
    
    # Link to next step
    if index < steps.length - 1
      task.next_task_id_on_success = "step_#{index + 1}"
    end
    
    workflow.add_task(task)
  end
  
  workflow
end

# Usage
steps = [
  { name: 'Step 1', handler: proc { |input| { step1: 'done' } } },
  { name: 'Step 2', handler: proc { |input| { step2: 'done' } } },
  { name: 'Step 3', handler: proc { |input| { step3: 'done' } } }
]

workflow = create_dynamic_workflow(steps)
```

This guide provides a comprehensive overview of working with workflows in rdawn. For more specific information about individual components, see the [TOOLS.md](TOOLS.md) and [DIRECT_HANDLERS.md](DIRECT_HANDLERS.md) guides. 