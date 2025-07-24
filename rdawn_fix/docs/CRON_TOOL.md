# CronTool - Task Scheduling with rdawn

The CronTool provides comprehensive task scheduling capabilities for the rdawn framework using the `rufus-scheduler` gem. It supports cron expressions, one-time scheduling, recurring intervals, and can execute procs, workflows, and other rdawn tools automatically.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Scheduling Methods](#scheduling-methods)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Advanced Features](#advanced-features)

## Overview

The CronTool integrates with rdawn's workflow system to provide:

- **Cron Expression Scheduling**: Standard Unix cron expressions
- **One-Time Scheduling**: Tasks that run at a specific future time
- **Recurring Intervals**: Simple interval-based scheduling (30s, 5m, 1h, etc.)
- **Tool Integration**: Schedule any rdawn tool to run automatically
- **Workflow Integration**: Schedule complete workflows (when available)
- **Event Callbacks**: Monitor job lifecycle with custom callbacks
- **Statistics Tracking**: Detailed execution metrics and monitoring
- **Job Management**: List, inspect, execute, and cancel scheduled jobs

## Installation

The CronTool is included with rdawn and uses the `rufus-scheduler` gem dependency:

```ruby
# Gemfile
gem 'rdawn'  # Includes rufus-scheduler dependency

# Or standalone
gem 'rufus-scheduler', '~> 3.9'
```

## Quick Start

### Basic Usage

```ruby
require 'rdawn'

# Initialize the CronTool
cron_tool = Rdawn::Tools::CronTool.new

# Schedule a simple task with cron expression
simple_task = proc do |input_data|
  puts "Daily report generated at #{Time.now}"
  { status: 'completed', generated_at: Time.now }
end

cron_tool.schedule_task(
  name: 'daily_report',
  cron_expression: '0 9 * * *',  # Daily at 9 AM
  task_proc: simple_task,
  input_data: { report_type: 'summary' }
)

# Let it run...
sleep(60)

# Check status
stats = cron_tool.get_statistics
puts "Active jobs: #{stats[:active_jobs]}"
```

### Using ToolRegistry

```ruby
# Register advanced tools (includes cron tools)
Rdawn::Tools.register_advanced_tools

# Schedule through ToolRegistry
Rdawn::ToolRegistry.execute('cron_schedule_task', {
  name: 'web_search_daily',
  cron_expression: '0 8 * * *',
  tool_name: 'web_search',
  input_data: { query: 'ruby on rails news' }
})

# List all jobs
jobs = Rdawn::ToolRegistry.execute('cron_list_jobs', {})
puts "Total scheduled jobs: #{jobs[:total_jobs]}"
```

## Scheduling Methods

### 1. Cron Expression Scheduling

Use standard Unix cron expressions for precise scheduling:

```ruby
# Daily at 9:00 AM
cron_tool.schedule_task(
  name: 'morning_report',
  cron_expression: '0 9 * * *',
  tool_name: 'report_generator'
)

# Every 15 minutes
cron_tool.schedule_task(
  name: 'health_check',
  cron_expression: '*/15 * * * *',
  tool_name: 'health_monitor'
)

# Weekdays at 6 PM
cron_tool.schedule_task(
  name: 'end_of_day_backup',
  cron_expression: '0 18 * * 1-5',
  tool_name: 'backup_service'
)
```

### 2. One-Time Scheduling

Schedule tasks to run once at a specific time:

```ruby
# Schedule for a specific time
cron_tool.schedule_once(
  name: 'maintenance_window',
  at_time: '2025-01-01 02:00:00',
  tool_name: 'maintenance_script'
)

# Schedule relative to now
cron_tool.schedule_once(
  name: 'delayed_notification',
  at_time: Time.now + 3600,  # 1 hour from now
  tool_name: 'notification_sender',
  input_data: { message: 'Scheduled notification' }
)
```

### 3. Recurring Intervals

Use simple interval expressions:

```ruby
# Every 30 seconds
cron_tool.schedule_recurring(
  name: 'heartbeat',
  interval: '30s',
  task_proc: proc { |data| puts "Heartbeat: #{Time.now}" }
)

# Every 5 minutes
cron_tool.schedule_recurring(
  name: 'metric_collection',
  interval: '5m',
  tool_name: 'metrics_collector'
)

# Every 2 hours
cron_tool.schedule_recurring(
  name: 'cache_cleanup',
  interval: '2h',
  tool_name: 'cache_cleaner'
)
```

## API Reference

### Core Methods

#### `schedule_task(name:, cron_expression:, **options)`

Schedule a task using cron expression.

**Parameters:**
- `name` (String): Unique name for the task
- `cron_expression` (String): Standard cron expression
- `task_proc` (Proc, optional): Custom proc to execute
- `workflow_id` (String, optional): Workflow ID to execute
- `tool_name` (String, optional): Tool name to execute
- `input_data` (Hash, optional): Data to pass to the task
- `options` (Hash, optional): Additional options

**Returns:** Hash with job information

```ruby
result = cron_tool.schedule_task(
  name: 'daily_task',
  cron_expression: '0 9 * * *',
  tool_name: 'data_processor',
  input_data: { source: 'database' },
  options: { retry_on_error: true }
)
# => { name: "daily_task", job_id: "cron_...", status: "scheduled", next_time: ... }
```

#### `schedule_once(name:, at_time:, **options)`

Schedule a one-time task.

**Parameters:**
- `name` (String): Unique name for the task
- `at_time` (Time|String): When to execute
- `task_proc` (Proc, optional): Custom proc to execute
- `workflow_id` (String, optional): Workflow ID to execute
- `tool_name` (String, optional): Tool name to execute
- `input_data` (Hash, optional): Data to pass to the task
- `options` (Hash, optional): Additional options

#### `schedule_recurring(name:, interval:, **options)`

Schedule a recurring task with interval.

**Parameters:**
- `name` (String): Unique name for the task
- `interval` (String): Interval expression (e.g., "30s", "5m", "1h")
- `task_proc` (Proc, optional): Custom proc to execute
- `workflow_id` (String, optional): Workflow ID to execute
- `tool_name` (String, optional): Tool name to execute
- `input_data` (Hash, optional): Data to pass to the task
- `options` (Hash, optional): Additional options

### Management Methods

#### `list_jobs()`

List all scheduled jobs.

```ruby
jobs = cron_tool.list_jobs
# => {
#   total_jobs: 3,
#   active_jobs: 2,
#   jobs: [
#     { name: "daily_report", type: "cron", status: "active", executions: 5, ... }
#   ]
# }
```

#### `get_job(name:)`

Get detailed information about a specific job.

```ruby
job = cron_tool.get_job(name: 'daily_report')
# => {
#   name: "daily_report",
#   job_id: "cron_...",
#   status: "active",
#   type: "cron",
#   executions: 5,
#   next_time: ...,
#   created_at: ...
# }
```

#### `execute_job_now(name:)`

Execute a job immediately (outside its schedule).

```ruby
result = cron_tool.execute_job_now(name: 'daily_report')
# => { name: "daily_report", executed_at: ..., result: ... }
```

#### `unschedule_job(name:)`

Remove a scheduled job.

```ruby
result = cron_tool.unschedule_job(name: 'daily_report')
# => { name: "daily_report", status: "unscheduled", unscheduled_at: ... }
```

#### `get_statistics()`

Get scheduler statistics.

```ruby
stats = cron_tool.get_statistics
# => {
#   scheduler_status: "running",
#   total_jobs: 5,
#   active_jobs: 3,
#   completed_jobs: 25,
#   failed_jobs: 1,
#   uptime: 3600.0
# }
```

### Lifecycle Methods

#### `stop_scheduler()`

Stop the scheduler.

```ruby
result = cron_tool.stop_scheduler
# => { status: "stopped", stopped_at: ... }
```

#### `restart_scheduler()`

Restart the scheduler.

```ruby
result = cron_tool.restart_scheduler
# => { status: "restarted", restarted_at: ... }
```

## Examples

### Example 1: Daily Report Generation

```ruby
# Schedule a daily report that uses web search
cron_tool.schedule_task(
  name: 'daily_news_report',
  cron_expression: '0 8 * * *',  # 8 AM daily
  tool_name: 'web_search',
  input_data: {
    query: 'Ruby on Rails latest news',
    context_size: 'medium'
  }
)
```

### Example 2: Periodic Health Checks

```ruby
# Health check every 5 minutes
health_check_proc = proc do |input_data|
  # Simulate health check
  status = rand > 0.1 ? 'healthy' : 'unhealthy'
  
  if status == 'unhealthy'
    puts "⚠️ Health check failed at #{Time.now}"
    # Could trigger alerts here
  end
  
  {
    status: status,
    checked_at: Time.now,
    server: input_data[:server] || 'default'
  }
end

cron_tool.schedule_recurring(
  name: 'server_health_check',
  interval: '5m',
  task_proc: health_check_proc,
  input_data: { server: 'web-01' }
)
```

### Example 3: Scheduled Data Cleanup

```ruby
# Daily cleanup at midnight
cleanup_proc = proc do |input_data|
  # Simulate cleanup
  days_old = input_data[:days_old] || 30
  
  # In a real app, this would clean up old records
  deleted_count = rand(100..500)
  
  puts "🧹 Cleaned up #{deleted_count} records older than #{days_old} days"
  
  {
    deleted_count: deleted_count,
    days_old: days_old,
    cleaned_at: Time.now
  }
end

cron_tool.schedule_task(
  name: 'nightly_cleanup',
  cron_expression: '0 0 * * *',  # Midnight daily
  task_proc: cleanup_proc,
  input_data: { days_old: 30 }
)
```

### Example 4: Maintenance Window

```ruby
# Schedule maintenance for a specific future time
maintenance_proc = proc do |input_data|
  puts "🔧 Starting maintenance at #{Time.now}"
  
  # Simulate maintenance tasks
  sleep(2)  # In real code, this would be actual maintenance
  
  puts "✅ Maintenance completed at #{Time.now}"
  
  {
    maintenance_type: input_data[:type],
    started_at: Time.now - 2,
    completed_at: Time.now,
    status: 'completed'
  }
end

cron_tool.schedule_once(
  name: 'scheduled_maintenance',
  at_time: '2025-01-15 02:00:00',
  task_proc: maintenance_proc,
  input_data: { type: 'database_optimization' }
)
```

### Example 5: Event Callbacks

```ruby
# Set up monitoring callbacks
cron_tool.set_callback(
  event: 'before_execution',
  callback_proc: proc do |job_name, job|
    puts "▶️  Starting job: #{job_name} at #{Time.now}"
  end
)

cron_tool.set_callback(
  event: 'after_execution',
  callback_proc: proc do |job_name, job, result|
    puts "✅ Completed job: #{job_name} - Result: #{result.class}"
  end
)

cron_tool.set_callback(
  event: 'on_error',
  callback_proc: proc do |job_name, job, error|
    puts "❌ Job failed: #{job_name} - Error: #{error.message}"
    # Could send alerts, log to external service, etc.
  end
)
```

## Best Practices

### 1. Unique Job Names

Always use unique, descriptive names for jobs:

```ruby
# Good
cron_tool.schedule_task(name: 'user_email_digest_daily', ...)
cron_tool.schedule_task(name: 'database_backup_nightly', ...)

# Bad
cron_tool.schedule_task(name: 'task1', ...)
cron_tool.schedule_task(name: 'job', ...)
```

### 2. Error Handling in Tasks

Handle errors gracefully in your task procs:

```ruby
robust_task = proc do |input_data|
  begin
    # Task logic here
    result = perform_operation(input_data)
    
    {
      success: true,
      result: result,
      executed_at: Time.now
    }
  rescue => e
    {
      success: false,
      error: e.message,
      executed_at: Time.now,
      input_data: input_data
    }
  end
end
```

### 3. Resource Management

Be mindful of resource usage in scheduled tasks:

```ruby
# Good: Process in batches
batch_processor = proc do |input_data|
  batch_size = input_data[:batch_size] || 100
  
  User.find_in_batches(batch_size: batch_size) do |batch|
    batch.each do |user|
      # Process individual user
    end
  end
  
  { processed_at: Time.now, batch_size: batch_size }
end

# Bad: Load all records at once
# User.all.each { |user| ... }  # Could cause memory issues
```

### 4. Timezone Considerations

Be explicit about timezones when scheduling:

```ruby
# Specify timezone in your environment
ENV['TZ'] = 'America/New_York'

# Or handle in your task
timezone_aware_task = proc do |input_data|
  now = Time.now
  utc_now = now.utc
  
  {
    local_time: now,
    utc_time: utc_now,
    timezone: Time.now.zone
  }
end
```

### 5. Monitoring and Alerting

Implement monitoring for critical scheduled tasks:

```ruby
# Set up callbacks for monitoring
cron_tool.set_callback(
  event: 'on_error',
  callback_proc: proc do |job_name, job, error|
    # Send alert for critical jobs
    if job_name.include?('critical') || job_name.include?('backup')
      send_alert("Critical job failed: #{job_name} - #{error.message}")
    end
    
    # Log all errors
    Rails.logger.error "Scheduled job failed: #{job_name} - #{error.message}"
  end
)
```

## Error Handling

### Common Error Scenarios

1. **Invalid Cron Expression**
```ruby
begin
  cron_tool.schedule_task(
    name: 'invalid_cron',
    cron_expression: 'invalid expression'
  )
rescue Rdawn::Errors::ConfigurationError => e
  puts "Invalid cron expression: #{e.message}"
end
```

2. **Duplicate Job Names**
```ruby
begin
  cron_tool.schedule_task(name: 'duplicate', cron_expression: '* * * * *')
  cron_tool.schedule_task(name: 'duplicate', cron_expression: '* * * * *')
rescue Rdawn::Errors::ConfigurationError => e
  puts "Duplicate job name: #{e.message}"
end
```

3. **Tool Not Found**
```ruby
begin
  cron_tool.schedule_task(
    name: 'missing_tool',
    cron_expression: '* * * * *',
    tool_name: 'nonexistent_tool'
  )
rescue Rdawn::Errors::ToolNotFoundError => e
  puts "Tool not found: #{e.message}"
end
```

### Error Recovery

```ruby
# Implement retry logic in tasks
retry_task = proc do |input_data|
  max_retries = input_data[:max_retries] || 3
  current_retry = input_data[:current_retry] || 0
  
  begin
    # Attempt operation
    result = risky_operation(input_data)
    { success: true, result: result, retries: current_retry }
    
  rescue => e
    if current_retry < max_retries
      # Schedule retry
      cron_tool.schedule_once(
        name: "#{input_data[:job_name]}_retry_#{current_retry + 1}",
        at_time: Time.now + (current_retry + 1) * 60,  # Exponential backoff
        task_proc: retry_task,
        input_data: input_data.merge(current_retry: current_retry + 1)
      )
      
      { success: false, retrying: true, retry_count: current_retry + 1 }
    else
      { success: false, error: e.message, max_retries_reached: true }
    end
  end
end
```

## Advanced Features

### 1. Dynamic Job Scheduling

```ruby
# Schedule jobs based on external conditions
def schedule_conditional_job(condition, job_config)
  if condition_met?(condition)
    cron_tool.schedule_task(job_config)
  else
    puts "Condition not met, skipping job: #{job_config[:name]}"
  end
end

# Schedule during business hours only
business_hours_job = {
  name: 'business_hours_task',
  cron_expression: '0 9-17 * * 1-5',  # 9 AM to 5 PM, weekdays
  tool_name: 'business_processor'
}

schedule_conditional_job(:business_hours_active, business_hours_job)
```

### 2. Job Chaining

```ruby
# Chain multiple jobs together
def schedule_job_chain(jobs)
  jobs.each_with_index do |job_config, index|
    if index == 0
      # Schedule first job normally
      cron_tool.schedule_task(job_config)
    else
      # Schedule subsequent jobs with dependencies
      previous_job = jobs[index - 1]
      
      # Create a wrapper that executes after previous job
      chain_proc = proc do |input_data|
        # Wait for previous job to complete
        wait_for_job_completion(previous_job[:name])
        
        # Execute current job
        Rdawn::ToolRegistry.execute(job_config[:tool_name], input_data)
      end
      
      cron_tool.schedule_task(
        job_config.merge(task_proc: chain_proc)
      )
    end
  end
end
```

### 3. Load Balancing

```ruby
# Distribute jobs across time to avoid resource conflicts
def schedule_with_load_balancing(jobs, interval_minutes = 5)
  jobs.each_with_index do |job_config, index|
    # Offset each job by the interval
    base_time = Time.parse(job_config[:base_time] || '09:00')
    offset_time = base_time + (index * interval_minutes * 60)
    
    # Convert to cron expression
    cron_expression = "#{offset_time.min} #{offset_time.hour} * * *"
    
    cron_tool.schedule_task(
      job_config.merge(cron_expression: cron_expression)
    )
  end
end

# Schedule multiple reports with 10-minute intervals
report_jobs = [
  { name: 'sales_report', tool_name: 'sales_reporter', base_time: '09:00' },
  { name: 'user_report', tool_name: 'user_reporter', base_time: '09:00' },
  { name: 'system_report', tool_name: 'system_reporter', base_time: '09:00' }
]

schedule_with_load_balancing(report_jobs, 10)
```

### 4. Configuration Management

```ruby
# Load job configurations from external source
class CronJobManager
  def initialize(cron_tool, config_source = 'config/scheduled_jobs.yml')
    @cron_tool = cron_tool
    @config_source = config_source
  end
  
  def load_and_schedule_jobs
    jobs_config = YAML.load_file(@config_source)
    
    jobs_config['jobs'].each do |job_config|
      case job_config['type']
      when 'cron'
        @cron_tool.schedule_task(
          name: job_config['name'],
          cron_expression: job_config['cron_expression'],
          tool_name: job_config['tool_name'],
          input_data: job_config['input_data'] || {}
        )
      when 'recurring'
        @cron_tool.schedule_recurring(
          name: job_config['name'],
          interval: job_config['interval'],
          tool_name: job_config['tool_name'],
          input_data: job_config['input_data'] || {}
        )
      end
    end
  end
end

# config/scheduled_jobs.yml
# jobs:
#   - name: daily_backup
#     type: cron
#     cron_expression: "0 2 * * *"
#     tool_name: backup_service
#   - name: health_check
#     type: recurring
#     interval: "5m"
#     tool_name: health_monitor
```

The CronTool provides a powerful and flexible foundation for implementing scheduled tasks in rdawn applications. For more information, see the [../examples/cron_example.rb](../examples/cron_example.rb) file for a comprehensive demonstration of all features. 