# Tools in rdawn

This guide explains how to use and create tools in the rdawn framework.

## Table of Contents

- [Overview](#overview)
- [Using Existing Tools](#using-existing-tools)
- [Creating Custom Tools](#creating-custom-tools)
- [Tool Registry](#tool-registry)
- [Built-in Tools](#built-in-tools)
- [Advanced Tool Patterns](#advanced-tool-patterns)
- [Best Practices](#best-practices)

## Overview

Tools in rdawn are reusable components that can be executed within workflows. They provide a way to encapsulate specific functionality that can be shared across different workflows and tasks. Tools can be simple functions, complex service objects, or even interfaces to external APIs.

### Current Tool Status ✅

All built-in tools are fully functional and production-ready:

- **Vector Store Tools** ✅ - Complete file upload, vector store management, and search capabilities
- **Web Search Tools** ✅ - Real-time web search with OpenAI's web search API
- **File Management Tools** ✅ - Upload, manage, and search files in vector stores
- **Cron Tools** ✅ - Comprehensive task scheduling with cron expressions
- **Markdown Tools** ✅ - AI-powered markdown generation, editing, and processing

These tools can be used immediately in your workflows and applications.

## Using Existing Tools

### Basic Tool Usage

```ruby
# Create a task that uses a tool
task = Rdawn::Task.new(
  task_id: 'format_text',
  name: 'Format Text',
  tool_name: 'text_formatter',
  input_data: {
    text: 'hello world',
    format: 'uppercase'
  }
)

# Add to workflow
workflow.add_task(task)
```

### Tool with Variable Resolution

```ruby
# Tools can use variables from the workflow
task = Rdawn::Task.new(
  task_id: 'process_user_data',
  name: 'Process User Data',
  tool_name: 'user_processor',
  input_data: {
    user_id: '${user_id}',
    action: 'update_profile',
    data: '${profile_data}'
  }
)
```

## Creating Custom Tools

### Simple Function Tool

```ruby
# Create a simple tool as a proc
text_formatter = proc do |input|
  text = input[:text] || input['text']
  format = input[:format] || input['format'] || 'none'
  
  case format
  when 'uppercase'
    { formatted_text: text.upcase, original: text }
  when 'lowercase'
    { formatted_text: text.downcase, original: text }
  when 'capitalize'
    { formatted_text: text.capitalize, original: text }
  else
    { formatted_text: text, original: text }
  end
end

# Register the tool
Rdawn::ToolRegistry.register('text_formatter', text_formatter)
```

### Class-Based Tool

```ruby
class EmailValidator
  def self.call(input)
    email = input[:email] || input['email']
    
    if email.nil? || email.empty?
      return { valid: false, error: 'Email is required' }
    end
    
    valid = email.match?(/\A[^@\s]+@[^@\s]+\z/)
    domain = email.split('@').last if valid
    
    {
      valid: valid,
      email: email,
      domain: domain,
      error: valid ? nil : 'Invalid email format'
    }
  end
end

# Register the tool
Rdawn::ToolRegistry.register('email_validator', EmailValidator.method(:call))
```

### Service Object Tool

```ruby
class UserAnalyzer
  def initialize(api_key: nil)
    @api_key = api_key
  end
  
  def call(input)
    user_id = input[:user_id] || input['user_id']
    analysis_type = input[:analysis_type] || input['analysis_type'] || 'basic'
    
    case analysis_type
    when 'basic'
      analyze_basic_info(user_id)
    when 'advanced'
      analyze_advanced_info(user_id)
    else
      { error: 'Unknown analysis type' }
    end
  end
  
  private
  
  def analyze_basic_info(user_id)
    # Basic analysis logic
    {
      user_id: user_id,
      analysis_type: 'basic',
      score: rand(1..100),
      completed_at: Time.now
    }
  end
  
  def analyze_advanced_info(user_id)
    # Advanced analysis logic
    {
      user_id: user_id,
      analysis_type: 'advanced',
      score: rand(1..100),
      metrics: {
        engagement: rand(1..10),
        satisfaction: rand(1..10)
      },
      completed_at: Time.now
    }
  end
end

# Register the tool
analyzer = UserAnalyzer.new(api_key: ENV['ANALYSIS_API_KEY'])
Rdawn::ToolRegistry.register('user_analyzer', analyzer.method(:call))
```

### API Integration Tool

```ruby
class WeatherService
  def initialize(api_key:)
    @api_key = api_key
  end
  
  def call(input)
    city = input[:city] || input['city']
    country = input[:country] || input['country'] || 'US'
    
    return { error: 'City is required' } if city.nil? || city.empty?
    
    begin
      weather_data = fetch_weather(city, country)
      {
        city: city,
        country: country,
        temperature: weather_data[:temperature],
        description: weather_data[:description],
        humidity: weather_data[:humidity],
        timestamp: Time.now
      }
    rescue => e
      { error: "Weather API error: #{e.message}" }
    end
  end
  
  private
  
  def fetch_weather(city, country)
    # Simulate API call
    {
      temperature: rand(15..35),
      description: ['sunny', 'cloudy', 'rainy'].sample,
      humidity: rand(30..80)
    }
  end
end

# Register the tool
weather_service = WeatherService.new(api_key: ENV['WEATHER_API_KEY'])
Rdawn::ToolRegistry.register('weather_service', weather_service.method(:call))
```

## Tool Registry

### Registering Tools

```ruby
# Register a simple proc
Rdawn::ToolRegistry.register('simple_tool', proc { |input| { result: 'processed' } })

# Register a method
Rdawn::ToolRegistry.register('method_tool', SomeClass.method(:process))

# Register a callable object
Rdawn::ToolRegistry.register('callable_tool', callable_object)
```

### Listing Registered Tools

```ruby
# Get all registered tools
tools = Rdawn::ToolRegistry.registered_tools
puts tools.keys  # ['simple_tool', 'method_tool', 'callable_tool']

# Check if a tool is registered
if Rdawn::ToolRegistry.registered?('text_formatter')
  puts "Text formatter is available"
end
```

### Executing Tools Directly

```ruby
# Execute a tool directly (outside of workflow)
result = Rdawn::ToolRegistry.execute('text_formatter', {
  text: 'hello world',
  format: 'uppercase'
})

puts result[:formatted_text]  # "HELLO WORLD"
```

## Built-in Tools

### Vector Store Tools ✅ (Fully Working)

The Vector Store Tools provide comprehensive file upload, vector store management, and file search capabilities using OpenAI's vector store API.

```ruby
# Create vector store
Rdawn::ToolRegistry.execute('vector_store_create', {
  name: 'My Knowledge Base',
  file_ids: ['file-123', 'file-456'],
  expires_after: { anchor: 'last_active_at', days: 30 }
})

# Upload files for vector store
Rdawn::ToolRegistry.execute('file_upload', {
  file_path: '/path/to/document.pdf',
  purpose: 'assistants'
})

# Search files in vector store
Rdawn::ToolRegistry.execute('file_search', {
  query: 'How to use rdawn?',
  vector_store_ids: ['vs-abc123'],
  max_results: 5,
  model: 'gpt-4o-mini'
})

# Get vector store information
Rdawn::ToolRegistry.execute('vector_store_get', {
  vector_store_id: 'vs-abc123'
})

# List all vector stores
Rdawn::ToolRegistry.execute('vector_store_list', {
  limit: 20,
  order: 'desc'
})

# Add file to existing vector store
Rdawn::ToolRegistry.execute('vector_store_add_file', {
  vector_store_id: 'vs-abc123',
  file_id: 'file-456'
})

# Delete vector store
Rdawn::ToolRegistry.execute('vector_store_delete', {
  vector_store_id: 'vs-abc123'
})
```

#### Available Vector Store Tools

- `vector_store_create` - Create new vector store
- `vector_store_get` - Get vector store details
- `vector_store_list` - List all vector stores
- `vector_store_delete` - Delete vector store
- `vector_store_add_file` - Add file to vector store
- `file_upload` - Upload files to OpenAI
- `file_upload_from_url` - Upload from URL
- `file_get_info` - Get file information
- `file_list` - List uploaded files
- `file_delete` - Delete files
- `file_search` - Search files in vector stores
- `file_search_with_context` - Search with additional context

### Web Search Tools ✅ (Fully Working)

The Web Search Tool provides real-time web search capabilities using OpenAI's web search API.

```ruby
# Basic web search
Rdawn::ToolRegistry.execute('web_search', {
  query: 'rdawn ruby framework',
  context_size: 'medium'  # 'low', 'medium', 'high'
})

# News search
Rdawn::ToolRegistry.execute('web_search_news', {
  query: 'AI frameworks 2024',
  context_size: 'large'
})

# Location-based search
Rdawn::ToolRegistry.execute('web_search', {
  query: 'best restaurants near me',
  context_size: 'medium',
  user_location: {
    type: 'approximate',
    country: 'GB',
    city: 'London',
    region: 'London'
  }
})

# Recent search with timeframe
Rdawn::ToolRegistry.execute('web_search_recent', {
  query: 'SpaceX launches',
  timeframe: 'today',  # 'today', 'this week', 'this month'
  context_size: 'medium'
})

# Search with filters
Rdawn::ToolRegistry.execute('web_search_with_filters', {
  query: 'machine learning',
  filters: {
    site: 'arxiv.org',
    filetype: 'pdf',
    custom: 'recent papers'
  },
  context_size: 'medium'
})
```

#### Using Web Search in Workflows

```ruby
# Example: Web search in a workflow task
task = Rdawn::Task.new(
  task_id: 'search_latest_news',
  name: 'Search Latest News',
  tool_name: 'web_search',
  input_data: {
    query: 'latest AI developments 2025',
    context_size: 'high'
  }
)

workflow.add_task(task)
```

#### Web Search Features

- **Real-time search results** from OpenAI's web search API
- **Context size control** (low, medium, high) for cost and quality balance
- **Location-based results** with user location settings
- **Time-filtered searches** (today, this week, this month)
- **Advanced filtering** by site, filetype, and custom filters
- **Batch search processing** for multiple queries
- **Usage tracking** and cost monitoring
- **Citation support** with source URLs and annotations

#### Available Web Search Tools

- `web_search` - Basic web search with customizable context
- `web_search_news` - News-focused search
- `web_search_recent` - Time-filtered search
- `web_search_with_filters` - Advanced filtering capabilities

### Cron Tools (Scheduling)

The CronTool provides comprehensive task scheduling capabilities using cron expressions, one-time scheduling, and recurring intervals.

```ruby
# Schedule a task with cron expression (daily at 9 AM)
Rdawn::ToolRegistry.execute('cron_schedule_task', {
  name: 'daily_report',
  cron_expression: '0 9 * * *',
  tool_name: 'web_search',
  input_data: { query: 'daily news' }
})

# Schedule a one-time task
Rdawn::ToolRegistry.execute('cron_schedule_once', {
  name: 'welcome_email',
  at_time: '2025-01-01 10:00:00',
  tool_name: 'email_sender',
  input_data: { template: 'welcome' }
})

# Schedule a recurring task (every 30 seconds)
Rdawn::ToolRegistry.execute('cron_schedule_recurring', {
  name: 'heartbeat_check',
  interval: '30s',
  tool_name: 'health_monitor'
})

# Schedule with custom proc
custom_task = proc do |input_data|
  puts "Executing at #{Time.now}"
  { message: 'Task completed', data: input_data }
end

Rdawn::ToolRegistry.execute('cron_schedule_task', {
  name: 'custom_task',
  cron_expression: '*/5 * * * *',  # Every 5 minutes
  task_proc: custom_task,
  input_data: { context: 'scheduled execution' }
})

# List all scheduled jobs
jobs = Rdawn::ToolRegistry.execute('cron_list_jobs', {})
puts "Total jobs: #{jobs[:total_jobs]}"

# Get job details
job_info = Rdawn::ToolRegistry.execute('cron_get_job', {
  name: 'daily_report'
})

# Execute a job immediately (outside schedule)
Rdawn::ToolRegistry.execute('cron_execute_job_now', {
  name: 'daily_report'
})

# Unschedule a job
Rdawn::ToolRegistry.execute('cron_unschedule_job', {
  name: 'daily_report'
})

# Get scheduler statistics
stats = Rdawn::ToolRegistry.execute('cron_get_statistics', {})
puts "Active jobs: #{stats[:active_jobs]}"
puts "Completed: #{stats[:completed_jobs]}"
```

#### Cron Expression Examples

```ruby
# Common cron expressions
'0 9 * * *'       # Daily at 9:00 AM
'0 */2 * * *'     # Every 2 hours
'0 9 * * 1'       # Every Monday at 9:00 AM
'0 0 1 * *'       # First day of every month at midnight
'*/15 * * * *'    # Every 15 minutes
'0 9-17 * * 1-5'  # Every hour from 9 AM to 5 PM, Monday to Friday
```

#### Interval Examples

```ruby
# Simple intervals
'30s'    # Every 30 seconds
'5m'     # Every 5 minutes
'2h'     # Every 2 hours
'1d'     # Every day
'1w'     # Every week
```

#### Available Cron Tools

- `cron_schedule_task` - Schedule with cron expressions
- `cron_schedule_once` - One-time scheduling
- `cron_schedule_recurring` - Recurring intervals
- `cron_unschedule_job` - Remove scheduled jobs
- `cron_list_jobs` - List all jobs
- `cron_get_job` - Get job details
- `cron_execute_job_now` - Execute immediately
- `cron_get_statistics` - Get scheduler stats
- `cron_stop_scheduler` - Stop the scheduler
- `cron_restart_scheduler` - Restart the scheduler

### Markdown Tools (AI-Powered)

```ruby
# Generate markdown content with AI
Rdawn::ToolRegistry.execute('markdown_generate', {
  prompt: 'Create a technical blog post about Ruby on Rails',
  style: 'technical',
  length: 'medium'
})

# Edit existing markdown with AI assistance
Rdawn::ToolRegistry.execute('markdown_edit', {
  markdown: '# My Document\n\nContent here...',
  instructions: 'Add more detail and improve readability'
})

# Convert markdown to HTML
Rdawn::ToolRegistry.execute('markdown_to_html', {
  markdown: '# Hello World\n\nThis is **bold** text.',
  github_style: true
})

# Generate table of contents
Rdawn::ToolRegistry.execute('markdown_generate_toc', {
  markdown: markdown_content,
  max_depth: 3,
  style: 'bullet'
})

# Validate markdown syntax
Rdawn::ToolRegistry.execute('markdown_validate', {
  markdown: markdown_content,
  strict: false
})

# Get AI suggestions for improvement
Rdawn::ToolRegistry.execute('markdown_suggest_improvements', {
  markdown: markdown_content,
  focus: 'readability'
})
```

## Advanced Tool Patterns

### Stateful Tools

```ruby
class StatefulCounter
  def initialize
    @count = 0
  end
  
  def call(input)
    action = input[:action] || input['action'] || 'increment'
    
    case action
    when 'increment'
      @count += (input[:amount] || input['amount'] || 1)
    when 'decrement'
      @count -= (input[:amount] || input['amount'] || 1)
    when 'reset'
      @count = 0
    end
    
    { count: @count, action: action }
  end
end

# Register stateful tool
counter = StatefulCounter.new
Rdawn::ToolRegistry.register('counter', counter.method(:call))

# Usage maintains state between calls
Rdawn::ToolRegistry.execute('counter', { action: 'increment' })      # { count: 1 }
Rdawn::ToolRegistry.execute('counter', { action: 'increment' })      # { count: 2 }
Rdawn::ToolRegistry.execute('counter', { action: 'decrement' })      # { count: 1 }
```

### Configurable Tools

```ruby
class ConfigurableProcessor
  def initialize(config = {})
    @config = {
      max_length: 100,
      format: 'json',
      validate: true
    }.merge(config)
  end
  
  def call(input)
    data = input[:data] || input['data']
    
    # Apply configuration
    if @config[:validate] && data.nil?
      return { error: 'Data is required' }
    end
    
    processed_data = process_data(data)
    
    if @config[:max_length] && processed_data.to_s.length > @config[:max_length]
      processed_data = processed_data.to_s[0...@config[:max_length]]
    end
    
    result = { processed_data: processed_data, config: @config }
    
    case @config[:format]
    when 'json'
      result
    when 'string'
      result.to_s
    else
      result
    end
  end
  
  private
  
  def process_data(data)
    "Processed: #{data}"
  end
end

# Register with different configurations
default_processor = ConfigurableProcessor.new
Rdawn::ToolRegistry.register('processor_default', default_processor.method(:call))

strict_processor = ConfigurableProcessor.new(max_length: 50, validate: true)
Rdawn::ToolRegistry.register('processor_strict', strict_processor.method(:call))
```

### Composite Tools

```ruby
class CompositeDataProcessor
  def initialize
    @validators = []
    @processors = []
    @formatters = []
  end
  
  def add_validator(validator)
    @validators << validator
  end
  
  def add_processor(processor)
    @processors << processor
  end
  
  def add_formatter(formatter)
    @formatters << formatter
  end
  
  def call(input)
    data = input[:data] || input['data']
    
    # Validation phase
    @validators.each do |validator|
      validation_result = validator.call(data)
      return { error: validation_result[:error] } unless validation_result[:valid]
    end
    
    # Processing phase
    processed_data = data
    @processors.each do |processor|
      processed_data = processor.call(processed_data)
    end
    
    # Formatting phase
    formatted_data = processed_data
    @formatters.each do |formatter|
      formatted_data = formatter.call(formatted_data)
    end
    
    {
      original: data,
      processed: processed_data,
      formatted: formatted_data,
      steps: @validators.length + @processors.length + @formatters.length
    }
  end
end

# Build composite tool
composite = CompositeDataProcessor.new
composite.add_validator(proc { |data| { valid: !data.nil? } })
composite.add_processor(proc { |data| data.to_s.strip })
composite.add_formatter(proc { |data| data.upcase })

Rdawn::ToolRegistry.register('composite_processor', composite.method(:call))
```

### Async Tools (Future Feature)

```ruby
class AsyncDataFetcher
  def initialize(timeout: 30)
    @timeout = timeout
  end
  
  def call(input)
    url = input[:url] || input['url']
    
    # Simulate async operation
    future = Concurrent::Future.execute do
      sleep(0.1)  # Simulate network delay
      fetch_data(url)
    end
    
    begin
      result = future.value(@timeout)
      { data: result, url: url, fetched_at: Time.now }
    rescue Concurrent::TimeoutError
      { error: 'Request timeout', url: url }
    end
  end
  
  private
  
  def fetch_data(url)
    # Simulate data fetching
    "Data from #{url}"
  end
end

# Register async tool
async_fetcher = AsyncDataFetcher.new(timeout: 10)
Rdawn::ToolRegistry.register('async_fetcher', async_fetcher.method(:call))
```

## Best Practices

### 1. Input Validation

```ruby
# Always validate inputs
email_tool = proc do |input|
  email = input[:email] || input['email']
  
  # Validate required fields
  return { error: 'Email is required' } if email.nil? || email.empty?
  
  # Validate format
  return { error: 'Invalid email format' } unless email.match?(/\A[^@\s]+@[^@\s]+\z/)
  
  # Process valid input
  { valid: true, email: email, domain: email.split('@').last }
end
```

### 2. Error Handling

```ruby
# Handle errors gracefully
robust_tool = proc do |input|
  begin
    # Tool logic here
    result = process_data(input)
    { success: true, result: result }
  rescue StandardError => e
    { success: false, error: e.message, input: input }
  end
end
```

### 3. Consistent Output Format

```ruby
# Use consistent output structure
consistent_tool = proc do |input|
  begin
    result = process_input(input)
    
    {
      success: true,
      data: result,
      timestamp: Time.now,
      metadata: {
        input_size: input.to_s.length,
        processing_time: 0.1
      }
    }
  rescue => e
    {
      success: false,
      error: e.message,
      timestamp: Time.now,
      metadata: {
        input_size: input.to_s.length
      }
    }
  end
end
```

### 4. Support Both String and Symbol Keys

```ruby
# Support both string and symbol keys
flexible_tool = proc do |input|
  # Use both string and symbol keys
  name = input[:name] || input['name']
  age = input[:age] || input['age']
  
  { processed_name: name, processed_age: age }
end
```

### 5. Documentation

```ruby
# Document your tools
class DocumentedTool
  # A comprehensive tool for processing user data
  #
  # @param input [Hash] Input data
  # @option input [String] :user_id User ID to process
  # @option input [String] :action Action to perform ('create', 'update', 'delete')
  # @option input [Hash] :data Additional data for the action
  #
  # @return [Hash] Result of the operation
  #   @option return [Boolean] :success Whether the operation succeeded
  #   @option return [Hash] :result The result data
  #   @option return [String] :error Error message if failed
  def self.call(input)
    # Implementation here
  end
end
```

### 6. Testing Tools

```ruby
# Test your tools
RSpec.describe 'EmailValidator' do
  it 'validates correct email format' do
    result = Rdawn::ToolRegistry.execute('email_validator', {
      email: 'test@example.com'
    })
    
    expect(result[:valid]).to be true
    expect(result[:domain]).to eq('example.com')
  end
  
  it 'rejects invalid email format' do
    result = Rdawn::ToolRegistry.execute('email_validator', {
      email: 'invalid-email'
    })
    
    expect(result[:valid]).to be false
    expect(result[:error]).to include('Invalid email format')
  end
end
```

### 7. Tool Naming Conventions

```ruby
# Use clear, descriptive names
Rdawn::ToolRegistry.register('user_email_validator', email_validator)
Rdawn::ToolRegistry.register('text_content_formatter', text_formatter)
Rdawn::ToolRegistry.register('weather_data_fetcher', weather_fetcher)

# Group related tools with prefixes
Rdawn::ToolRegistry.register('email_validator', email_validator)
Rdawn::ToolRegistry.register('email_sender', email_sender)
Rdawn::ToolRegistry.register('email_parser', email_parser)
```

## Tool Categories

### Data Processing Tools

```ruby
# Text processing
Rdawn::ToolRegistry.register('text_cleaner', text_cleaner)
Rdawn::ToolRegistry.register('markdown_parser', markdown_parser)
Rdawn::ToolRegistry.register('json_formatter', json_formatter)

# Data transformation
Rdawn::ToolRegistry.register('csv_parser', csv_parser)
Rdawn::ToolRegistry.register('data_validator', data_validator)
Rdawn::ToolRegistry.register('data_aggregator', data_aggregator)
```

### External API Tools

```ruby
# Third-party integrations
Rdawn::ToolRegistry.register('slack_notifier', slack_notifier)
Rdawn::ToolRegistry.register('stripe_payment', stripe_payment)
Rdawn::ToolRegistry.register('sendgrid_mailer', sendgrid_mailer)
```

### Utility Tools

```ruby
# Common utilities
Rdawn::ToolRegistry.register('date_formatter', date_formatter)
Rdawn::ToolRegistry.register('url_validator', url_validator)
Rdawn::ToolRegistry.register('file_hasher', file_hasher)
```

This guide provides a comprehensive overview of working with tools in rdawn. For more information about integrating tools into workflows, see the [WORKFLOWS.md](WORKFLOWS.md) guide. 