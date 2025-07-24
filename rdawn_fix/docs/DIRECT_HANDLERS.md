# DirectHandlerTask in rdawn

This guide explains how to use DirectHandlerTask, the most flexible and powerful task type in rdawn.

## Table of Contents

- [Overview](#overview)
- [Basic Usage](#basic-usage)
- [Handler Types](#handler-types)
- [Parameter Handling](#parameter-handling)
- [Rails Integration](#rails-integration)
- [Advanced Patterns](#advanced-patterns)
- [Best Practices](#best-practices)
- [Testing](#testing)

## Overview

DirectHandlerTask is a task type that allows you to execute arbitrary Ruby code directly within your workflows. This provides maximum flexibility for integrating with existing Ruby and Rails applications, accessing databases, calling external APIs, and implementing complex business logic.

## Basic Usage

### Simple Handler

```ruby
# Basic handler with input data
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'simple_handler',
  name: 'Simple Handler',
  handler: proc do |input_data|
    name = input_data[:name] || 'World'
    { greeting: "Hello, #{name}!" }
  end
)

# Add to workflow
workflow.add_task(task)
```

### Handler with Multiple Parameters

```ruby
# Handler that receives both input data and workflow variables
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'multi_param_handler',
  name: 'Multi Parameter Handler',
  handler: proc do |input_data, workflow_vars|
    user_id = input_data[:user_id]
    previous_result = workflow_vars[:previous_result]
    
    {
      user_id: user_id,
      processed_result: "Processed: #{previous_result}",
      timestamp: Time.now
    }
  end
)
```

## Handler Types

### Proc/Lambda Handlers

```ruby
# Using a proc (most common)
simple_proc = proc do |input_data|
  { result: "Processed: #{input_data[:data]}" }
end

# Using a lambda (stricter argument checking)
strict_lambda = lambda do |input_data|
  { result: "Processed: #{input_data[:data]}" }
end

# Using a stabby lambda (Ruby 1.9+ syntax)
stabby_lambda = ->(input_data) { { result: "Processed: #{input_data[:data]}" } }
```

### Method Handlers

```ruby
class DataProcessor
  def self.process_data(input_data)
    data = input_data[:data]
    { processed: data.upcase, length: data.length }
  end
end

# Use method as handler
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'method_handler',
  name: 'Method Handler',
  handler: DataProcessor.method(:process_data)
)
```

### Class Instance Handlers

```ruby
class StatefulProcessor
  def initialize
    @count = 0
  end
  
  def call(input_data)
    @count += 1
    {
      result: "Processed item #{@count}",
      data: input_data[:data],
      processing_count: @count
    }
  end
end

# Use instance method as handler
processor = StatefulProcessor.new
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'instance_handler',
  name: 'Instance Handler',
  handler: processor.method(:call)
)
```

## Parameter Handling

### No Parameters

```ruby
# Handler that takes no parameters
simple_handler = proc do
  { timestamp: Time.now, status: 'ready' }
end
```

### One Parameter (Input Data)

```ruby
# Handler that only receives input data
input_handler = proc do |input_data|
  { received_data: input_data, processed_at: Time.now }
end
```

### Two Parameters (Input Data + Workflow Variables)

```ruby
# Handler that receives input data and workflow variables
full_handler = proc do |input_data, workflow_vars|
  {
    input: input_data,
    workflow_context: workflow_vars,
    combined_result: "#{input_data[:name]} - #{workflow_vars[:status]}"
  }
end
```

### Keyword Arguments

```ruby
# Handler using keyword arguments
keyword_handler = proc do |user_id:, name:, **other_vars|
  {
    user_id: user_id,
    name: name,
    other_data: other_vars
  }
end

# Use with input data that has matching keys
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'keyword_handler',
  name: 'Keyword Handler',
  handler: keyword_handler,
  input_data: { user_id: 123, name: 'John', extra: 'data' }
)
```

## Rails Integration

### ActiveRecord Integration

```ruby
# Handler that works with Rails models
user_handler = proc do |input_data|
  user = User.find(input_data[:user_id])
  user.update!(last_login: Time.current)
  
  {
    user: user.attributes,
    updated: true,
    last_login: user.last_login
  }
end

# Create user with associations
create_user_handler = proc do |input_data|
  user = User.create!(
    name: input_data[:name],
    email: input_data[:email]
  )
  
  # Create associated records
  profile = user.create_profile!(
    bio: input_data[:bio] || 'No bio provided'
  )
  
  {
    user: user.attributes,
    profile: profile.attributes,
    created: true
  }
end
```

### Service Object Integration

```ruby
# Rails service object
class UserOnboardingService
  def initialize(user_id)
    @user = User.find(user_id)
  end
  
  def call
    ActiveRecord::Base.transaction do
      @user.update!(onboarded: true, onboarded_at: Time.current)
      create_default_preferences
      send_welcome_email
    end
    
    {
      user_id: @user.id,
      onboarded: true,
      preferences_created: true,
      welcome_email_sent: true
    }
  end
  
  private
  
  def create_default_preferences
    @user.create_preference!(
      notifications: true,
      theme: 'light'
    )
  end
  
  def send_welcome_email
    UserMailer.welcome(@user).deliver_now
  end
end

# Use service object in handler
onboarding_handler = proc do |input_data|
  service = UserOnboardingService.new(input_data[:user_id])
  service.call
end
```

### Controller Integration

```ruby
# Handler that integrates with Rails controllers
class WorkflowController < ApplicationController
  def execute_user_workflow
    workflow = build_user_workflow
    
    # Handler that has access to controller context
    controller_handler = proc do |input_data|
      # Access current_user, session, etc.
      user = current_user
      
      # Use Rails helpers
      formatted_date = helpers.time_ago_in_words(user.created_at)
      
      # Access params
      additional_data = params[:workflow_data]
      
      {
        user: user.attributes,
        formatted_date: formatted_date,
        additional_data: additional_data,
        processed_by: 'workflow'
      }
    end
    
    task = Rdawn::Tasks::DirectHandlerTask.new(
      task_id: 'controller_context',
      name: 'Controller Context Handler',
      handler: controller_handler
    )
    
    workflow.add_task(task)
    
    # Execute workflow
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
    result = agent.run(initial_input: { user_id: current_user.id })
    
    render json: result
  end
end
```

### Background Job Integration

```ruby
# Handler that enqueues background jobs
job_handler = proc do |input_data|
  # Enqueue background job
  ProcessUserDataJob.perform_later(input_data[:user_id])
  
  # Enqueue multiple jobs
  [
    SendWelcomeEmailJob,
    CreateUserAnalyticsJob,
    UpdateUserStatsJob
  ].each do |job_class|
    job_class.perform_later(input_data[:user_id])
  end
  
  {
    jobs_enqueued: 4,
    user_id: input_data[:user_id],
    enqueued_at: Time.current
  }
end
```

## Advanced Patterns

### Error Handling

```ruby
# Handler with comprehensive error handling
robust_handler = proc do |input_data|
  begin
    user_id = input_data[:user_id]
    
    # Validate input
    raise ArgumentError, 'User ID is required' if user_id.nil?
    
    # Process data
    user = User.find(user_id)
    result = complex_processing(user)
    
    {
      success: true,
      user_id: user_id,
      result: result,
      processed_at: Time.current
    }
  rescue ActiveRecord::RecordNotFound => e
    {
      success: false,
      error: 'User not found',
      user_id: user_id,
      error_type: 'not_found'
    }
  rescue ArgumentError => e
    {
      success: false,
      error: e.message,
      error_type: 'validation'
    }
  rescue => e
    Rails.logger.error "Handler error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    {
      success: false,
      error: 'Internal processing error',
      error_type: 'internal'
    }
  end
end
```

### Conditional Logic

```ruby
# Handler with conditional processing
conditional_handler = proc do |input_data, workflow_vars|
  user_type = workflow_vars[:user_type]
  
  case user_type
  when 'premium'
    process_premium_user(input_data)
  when 'standard'
    process_standard_user(input_data)
  when 'trial'
    process_trial_user(input_data)
  else
    { error: 'Unknown user type', user_type: user_type }
  end
end

def process_premium_user(input_data)
  {
    features: ['advanced_analytics', 'priority_support', 'custom_reports'],
    limits: { api_calls: 10000, storage: '100GB' },
    user_type: 'premium'
  }
end

def process_standard_user(input_data)
  {
    features: ['basic_analytics', 'standard_support'],
    limits: { api_calls: 1000, storage: '10GB' },
    user_type: 'standard'
  }
end

def process_trial_user(input_data)
  {
    features: ['basic_analytics'],
    limits: { api_calls: 100, storage: '1GB' },
    trial_expires: 14.days.from_now,
    user_type: 'trial'
  }
end
```

### Data Transformation

```ruby
# Handler that transforms data structures
transformer_handler = proc do |input_data|
  raw_data = input_data[:raw_data]
  
  # Transform array of hashes
  transformed = raw_data.map do |item|
    {
      id: item['id'],
      name: item['name']&.titleize,
      email: item['email']&.downcase,
      created_at: Time.parse(item['created_at']),
      metadata: {
        source: item['source'] || 'unknown',
        processed_at: Time.current
      }
    }
  end
  
  {
    original_count: raw_data.length,
    transformed_count: transformed.length,
    transformed_data: transformed,
    transformation_completed: true
  }
end
```

### File Processing

```ruby
# Handler that processes files
file_processor = proc do |input_data|
  file_path = input_data[:file_path]
  
  # Read and process file
  content = File.read(file_path)
  lines = content.lines.map(&:strip)
  
  # Process each line
  processed_lines = lines.map.with_index do |line, index|
    {
      line_number: index + 1,
      content: line,
      length: line.length,
      word_count: line.split.length
    }
  end
  
  {
    file_path: file_path,
    total_lines: lines.length,
    processed_lines: processed_lines,
    file_size: File.size(file_path),
    processed_at: Time.current
  }
end
```

## Best Practices

### 1. Keep Handlers Focused

```ruby
# Good - single responsibility
email_validator = proc do |input_data|
  email = input_data[:email]
  valid = email.match?(/\A[^@\s]+@[^@\s]+\z/)
  
  { valid: valid, email: email }
end

# Avoid - too many responsibilities
monolithic_handler = proc do |input_data|
  # Don't do validation, database updates, email sending,
  # file processing, and API calls all in one handler
end
```

### 2. Use Descriptive Names

```ruby
# Good
validate_user_email_handler = proc { |input| validate_email(input[:email]) }
send_welcome_email_handler = proc { |input| send_welcome_email(input[:user_id]) }
process_payment_handler = proc { |input| process_payment(input[:payment_data]) }

# Avoid
h1 = proc { |input| validate_email(input[:email]) }
handler = proc { |input| send_welcome_email(input[:user_id]) }
```

### 3. Handle Errors Gracefully

```ruby
# Good error handling
safe_handler = proc do |input_data|
  begin
    result = risky_operation(input_data)
    { success: true, result: result }
  rescue SpecificError => e
    { success: false, error: e.message, recoverable: true }
  rescue => e
    Rails.logger.error "Unexpected error: #{e.message}"
    { success: false, error: 'Internal error', recoverable: false }
  end
end
```

### 4. Validate Input Data

```ruby
# Good input validation
validating_handler = proc do |input_data|
  # Check required fields
  required_fields = [:user_id, :action, :data]
  missing_fields = required_fields - input_data.keys
  
  unless missing_fields.empty?
    return { error: "Missing required fields: #{missing_fields.join(', ')}" }
  end
  
  # Validate data types
  unless input_data[:user_id].is_a?(Integer)
    return { error: 'User ID must be an integer' }
  end
  
  # Process valid input
  process_data(input_data)
end
```

### 5. Use Consistent Return Formats

```ruby
# Good - consistent return format
consistent_handler = proc do |input_data|
  begin
    result = process_data(input_data)
    
    {
      success: true,
      data: result,
      timestamp: Time.current,
      handler: 'consistent_handler'
    }
  rescue => e
    {
      success: false,
      error: e.message,
      timestamp: Time.current,
      handler: 'consistent_handler'
    }
  end
end
```

### 6. Log Important Operations

```ruby
# Good logging practices
logging_handler = proc do |input_data|
  Rails.logger.info "Starting handler execution with input: #{input_data}"
  
  begin
    result = process_data(input_data)
    Rails.logger.info "Handler completed successfully: #{result}"
    
    { success: true, result: result }
  rescue => e
    Rails.logger.error "Handler failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    { success: false, error: e.message }
  end
end
```

## Testing

### Unit Testing Handlers

```ruby
# Test handlers directly
RSpec.describe 'Email Validation Handler' do
  let(:email_validator) do
    proc do |input_data|
      email = input_data[:email]
      valid = email.match?(/\A[^@\s]+@[^@\s]+\z/)
      { valid: valid, email: email }
    end
  end
  
  it 'validates correct email' do
    result = email_validator.call({ email: 'test@example.com' })
    expect(result[:valid]).to be true
  end
  
  it 'rejects invalid email' do
    result = email_validator.call({ email: 'invalid-email' })
    expect(result[:valid]).to be false
  end
end
```

### Integration Testing

```ruby
# Test handlers within workflows
RSpec.describe 'User Onboarding Workflow' do
  let(:workflow) { create_user_onboarding_workflow }
  let(:agent) { Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm) }
  
  it 'completes user onboarding successfully' do
    result = agent.run(initial_input: { 
      user_id: create(:user).id,
      onboarding_type: 'premium' 
    })
    
    expect(result.status).to eq(:completed)
    
    # Check specific handler results
    onboarding_task = result.tasks['onboard_user']
    expect(onboarding_task.status).to eq(:completed)
    expect(onboarding_task.output_data[:handler_result][:success]).to be true
  end
end
```

### Mocking External Dependencies

```ruby
# Mock external services in handlers
RSpec.describe 'Payment Processing Handler' do
  let(:payment_handler) do
    proc do |input_data|
      payment_service = PaymentService.new
      result = payment_service.process_payment(input_data[:payment_data])
      { payment_result: result }
    end
  end
  
  it 'processes payment successfully' do
    # Mock the payment service
    mock_service = double('PaymentService')
    allow(PaymentService).to receive(:new).and_return(mock_service)
    allow(mock_service).to receive(:process_payment).and_return({ success: true })
    
    result = payment_handler.call({ payment_data: { amount: 100 } })
    expect(result[:payment_result][:success]).to be true
  end
end
```

This guide provides a comprehensive overview of using DirectHandlerTask in rdawn. For more information about integrating handlers into complete workflows, see the [WORKFLOWS.md](WORKFLOWS.md) guide. 