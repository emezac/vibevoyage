# MCP Integration Guide for rdawn

This guide explains how to integrate Model Context Protocol (MCP) servers with the rdawn framework for building powerful AI workflows.

## Table of Contents

- [Overview](#overview)
- [What is MCP?](#what-is-mcp)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [MCP Components](#mcp-components)
- [Workflow Integration](#workflow-integration)
- [Rails Integration](#rails-integration)
- [Advanced Features](#advanced-features)
- [Error Handling](#error-handling)
- [Performance Tips](#performance-tips)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The Model Context Protocol (MCP) integration in rdawn allows you to:

- Connect to external MCP servers using stdio transport
- Execute tools provided by MCP servers
- Access resources and prompts from MCP servers
- Build complex workflows that combine MCP tools with LLM tasks
- Handle both synchronous and asynchronous MCP operations

## What is MCP?

MCP (Model Context Protocol) is an open standard for connecting AI applications to external data sources and tools. It provides a standardized way for Large Language Models (LLMs) to interact with:

- **Tools**: Functions that can be executed (like APIs or system operations)
- **Resources**: Data sources that can be read (like files or databases)
- **Prompts**: Templates for guiding LLM interactions

MCP servers communicate via JSON-RPC 2.0 over various transports (stdio, HTTP, SSE).

## Installation

MCP integration is included with rdawn. You'll need to install MCP servers separately:

```bash
# Install common MCP servers
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-sqlite
npm install -g @modelcontextprotocol/server-git
```

## Basic Usage

### 1. Register an MCP Server

```ruby
require 'rdawn'

# Register a filesystem MCP server
Rdawn::Tools.register_mcp_server('filesystem', {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
  env: {},
  timeout: 30,
  auto_register_tools: true
})
```

### 2. List Available Tools

```ruby
# List all registered MCP servers
servers = Rdawn::Tools.list_mcp_servers
puts "Servers: #{servers}"

# List tools for a specific server
tools = Rdawn::Tools.list_mcp_server_tools('filesystem')
puts "Filesystem tools: #{tools}"
```

### 3. Execute MCP Tools

```ruby
# Execute a tool synchronously
result = Rdawn::Tools.execute_mcp_tool(
  'filesystem',
  'list_directory',
  { path: '/tmp' }
)

# Execute a tool asynchronously
future = Rdawn::Tools.execute_mcp_tool_async(
  'filesystem',
  'list_directory',
  { path: '/tmp' }
)
result = future.value!(10) # Wait up to 10 seconds
```

## MCP Components

### MCPTool Class

The `MCPTool` class handles direct communication with MCP servers:

```ruby
mcp_tool = Rdawn::Tools::MCPTool.new(
  server_name: 'filesystem',
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
  timeout: 30
)

# Connect to server
mcp_tool.connect

# List available tools
tools = mcp_tool.list_tools

# Execute a tool
result = mcp_tool.call_tool('list_directory', { path: '/tmp' })

# Disconnect
mcp_tool.disconnect
```

### MCPTaskExecutor Class

The `MCPTaskExecutor` manages multiple MCP servers and provides async execution:

```ruby
executor = Rdawn::Tools::MCPTaskExecutor.new(thread_pool_size: 5)

# Register servers
executor.register_server('filesystem', {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp']
})

# Execute tools
result = executor.execute_sync('filesystem', 'list_directory', { path: '/tmp' })
future = executor.execute_async('filesystem', 'list_directory', { path: '/tmp' })

# Shutdown
executor.shutdown
```

### MCPManager Class

The `MCPManager` provides a high-level interface for managing MCP servers:

```ruby
# Register a server
Rdawn::MCPManager.register_server('sqlite', {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-sqlite', '/tmp/test.db'],
  auto_register_tools: true
})

# Execute tools
result = Rdawn::MCPManager.execute_tool('sqlite', 'execute_query', {
  query: 'SELECT * FROM users'
})

# Check server status
connected = Rdawn::MCPManager.instance.server_connected?('sqlite')
```

## Workflow Integration

### Creating MCP Tasks

Use the `MCPTask` class for MCP operations in workflows:

```ruby
# Create an MCP task
mcp_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'list_files',
  name: 'List Project Files',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'list_directory',
  input_data: { path: '/project' },
  async_execution: false,
  timeout: 30
)

# Add to workflow
workflow = Rdawn::Workflow.new(workflow_id: 'mcp_demo', name: 'MCP Demo')
workflow.add_task(mcp_task)
```

### Building Complex Workflows

```ruby
workflow = Rdawn::Workflow.new(
  workflow_id: 'code_analysis',
  name: 'Code Analysis Workflow'
)

# Task 1: List files in project
list_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'list_files',
  name: 'List Files',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'list_directory',
  input_data: { path: '/project' },
  next_task_id_on_success: 'read_main_file'
)

# Task 2: Read main file
read_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'read_main_file',
  name: 'Read Main File',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'read_file',
  input_data: { path: '/project/main.rb' },
  next_task_id_on_success: 'analyze_code'
)

# Task 3: Analyze code with LLM
analyze_task = Rdawn::Task.new(
  task_id: 'analyze_code',
  name: 'Analyze Code',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this Ruby code: ${read_main_file.mcp_result}',
    model_params: { temperature: 0.3, max_tokens: 1000 }
  }
)

workflow.add_task(list_task)
workflow.add_task(read_task)
workflow.add_task(analyze_task)

# Execute workflow
llm_interface = Rdawn::LLMInterface.new(api_key: 'your_api_key')
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
result = agent.run
```

## Rails Integration

### Configuration

Add MCP server registration to your Rails initializer:

```ruby
# config/initializers/rdawn.rb
Rdawn.configure do |config|
  config.llm_api_key = ENV['RDAWN_LLM_API_KEY']
  config.llm_model = 'gpt-4o-mini'
end

# Register MCP servers
Rdawn::Tools.register_mcp_server('filesystem', {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', Rails.root.to_s],
  auto_register_tools: true
})

Rdawn::Tools.register_mcp_server('sqlite', {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-sqlite', Rails.root.join('db', 'development.sqlite3').to_s],
  auto_register_tools: true
})
```

### Rails Workflow Example

```ruby
# app/workflows/project_analysis_workflow.rb
class ProjectAnalysisWorkflow
  def self.build_workflow(project_path)
    {
      workflow_id: "project_analysis_#{SecureRandom.hex(8)}",
      name: 'Project Analysis Workflow',
      tasks: {
        'analyze_structure' => {
          type: 'mcp',
          name: 'Analyze Project Structure',
          mcp_server_name: 'filesystem',
          mcp_tool_name: 'list_directory',
          input_data: { path: project_path },
          next_task_id_on_success: 'generate_report'
        },
        'generate_report' => {
          type: 'llm',
          name: 'Generate Analysis Report',
          input_data: {
            prompt: 'Generate a project analysis report for: ${analyze_structure.mcp_result}',
            model_params: { temperature: 0.3 }
          },
          next_task_id_on_success: 'save_report'
        },
        'save_report' => {
          type: 'direct_handler',
          name: 'Save Report',
          handler: 'ReportHandler#save_analysis',
          input_data: { 
            report: '${generate_report.llm_response}',
            project_path: project_path
          }
        }
      }
    }
  end
  
  def self.analyze_project(project_path)
    workflow_data = build_workflow(project_path)
    
    Rdawn::Rails::WorkflowJob.run_workflow_later(
      workflow_data: workflow_data,
      llm_config: { api_key: ENV['RDAWN_LLM_API_KEY'] },
      initial_input: { project_path: project_path }
    )
  end
end
```

### Controller Integration

```ruby
# app/controllers/analysis_controller.rb
class AnalysisController < ApplicationController
  def analyze_project
    project_path = params[:project_path]
    
    # Start MCP workflow
    ProjectAnalysisWorkflow.analyze_project(project_path)
    
    render json: { 
      message: 'Analysis started',
      status: 'processing'
    }
  end
  
  def mcp_status
    servers = Rdawn::Tools.list_mcp_servers
    status = servers.map do |server_name|
      {
        name: server_name,
        connected: Rdawn::MCPManager.instance.server_connected?(server_name),
        tools: Rdawn::Tools.list_mcp_server_tools(server_name)
      }
    end
    
    render json: { servers: status }
  end
end
```

## Advanced Features

### Multi-Server Workflows

```ruby
# Register multiple servers
server_configs = {
  'filesystem' => {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem', '/project']
  },
  'git' => {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-git', '/project']
  },
  'sqlite' => {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-sqlite', '/project/db.sqlite3']
  }
}

workflow_info = Rdawn::Tools.create_mcp_workflow(
  server_configs: server_configs,
  workflow_name: 'Multi-Server Analysis'
)
```

### Resource Access

```ruby
# Read resources from MCP servers
resource_content = Rdawn::MCPManager.instance.read_server_resource(
  'filesystem',
  'file:///project/README.md'
)

# List available resources
resources = Rdawn::MCPManager.instance.list_server_resources('filesystem')
```

### Prompt Templates

```ruby
# Get prompt templates from MCP servers
prompts = Rdawn::MCPManager.instance.executor.get_or_create_tool('filesystem').list_prompts

# Use a prompt template
prompt_result = Rdawn::MCPManager.instance.executor.get_or_create_tool('filesystem').get_prompt(
  'analyze_code',
  { file_path: '/project/main.rb' }
)
```

## Error Handling

### Common Error Types

```ruby
begin
  result = Rdawn::Tools.execute_mcp_tool('server', 'tool', {})
rescue Rdawn::Errors::ToolNotFoundError => e
  Rails.logger.error "MCP tool not found: #{e.message}"
rescue Rdawn::Errors::TaskExecutionError => e
  Rails.logger.error "MCP task execution failed: #{e.message}"
rescue Rdawn::Errors::ConfigurationError => e
  Rails.logger.error "MCP configuration error: #{e.message}"
rescue => e
  Rails.logger.error "Unexpected MCP error: #{e.message}"
end
```

### Connection Recovery

```ruby
# Check server connection
unless Rdawn::MCPManager.instance.server_connected?('filesystem')
  # Attempt to reconnect
  begin
    Rdawn::MCPManager.instance.executor.get_or_create_tool('filesystem').connect
  rescue => e
    Rails.logger.error "Failed to reconnect to MCP server: #{e.message}"
  end
end
```

## Performance Tips

### 1. Use Async Execution for Long Tasks

```ruby
# For long-running operations
future = Rdawn::Tools.execute_mcp_tool_async('filesystem', 'large_operation', {})

# Continue with other work...

# Get result when ready
result = future.value!(60) # 60 second timeout
```

### 2. Configure Thread Pool Size

```ruby
# Configure thread pool for concurrent operations
executor = Rdawn::Tools::MCPTaskExecutor.new(thread_pool_size: 10)
```

### 3. Set Appropriate Timeouts

```ruby
# Configure timeouts based on operation type
fast_config = { timeout: 5 }   # For quick operations
slow_config = { timeout: 60 }  # For complex operations
```

## Best Practices

### 1. Server Registration

```ruby
# Register servers at application startup
# config/initializers/rdawn.rb
Rails.application.config.after_initialize do
  Rdawn::Tools.register_mcp_server('filesystem', {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem', Rails.root.to_s],
    auto_register_tools: true
  })
end
```

### 2. Error Handling

```ruby
# Always implement comprehensive error handling
begin
  result = Rdawn::Tools.execute_mcp_tool(server, tool, args)
rescue Rdawn::Errors::ToolNotFoundError
  # Handle missing tools
rescue Rdawn::Errors::TaskExecutionError
  # Handle execution failures
rescue => e
  # Handle unexpected errors
end
```

### 3. Resource Management

```ruby
# Clean up resources on shutdown
at_exit do
  Rdawn::Tools.shutdown_mcp
end
```

### 4. Monitoring

```ruby
# Monitor server health
def check_mcp_health
  servers = Rdawn::Tools.list_mcp_servers
  servers.each do |server_name|
    connected = Rdawn::MCPManager.instance.server_connected?(server_name)
    Rails.logger.info "MCP server #{server_name}: #{connected ? 'connected' : 'disconnected'}"
  end
end
```

## Examples

### File Analysis Workflow

```ruby
workflow = Rdawn::Workflow.new(
  workflow_id: 'file_analysis',
  name: 'File Analysis Workflow'
)

# Read file
read_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'read_file',
  name: 'Read File',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'read_file',
  input_data: { path: '/project/config.json' },
  next_task_id_on_success: 'analyze_config'
)

# Analyze with LLM
analyze_task = Rdawn::Task.new(
  task_id: 'analyze_config',
  name: 'Analyze Configuration',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this configuration: ${read_file.mcp_result}',
    model_params: { temperature: 0.2 }
  }
)

workflow.add_task(read_task)
workflow.add_task(analyze_task)
```

### Database Query Workflow

```ruby
# Query database
query_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'query_users',
  name: 'Query Users',
  mcp_server_name: 'sqlite',
  mcp_tool_name: 'execute_query',
  input_data: { 
    query: 'SELECT name, email FROM users WHERE active = 1 LIMIT 10'
  },
  next_task_id_on_success: 'process_results'
)

# Process results
process_task = Rdawn::Task.new(
  task_id: 'process_results',
  name: 'Process User Data',
  is_llm_task: true,
  input_data: {
    prompt: 'Summarize these users: ${query_users.mcp_result}',
    model_params: { temperature: 0.1 }
  }
)
```

## Troubleshooting

### Common Issues

1. **Server Not Starting**
   - Check that MCP server is installed: `npx @modelcontextprotocol/server-filesystem --version`
   - Verify command path and arguments
   - Check environment variables

2. **Tool Not Found**
   - Verify server registration: `Rdawn::Tools.list_mcp_servers`
   - Check tool availability: `Rdawn::Tools.list_mcp_server_tools('server_name')`
   - Ensure auto-registration is enabled

3. **Timeout Errors**
   - Increase timeout values for slow operations
   - Use async execution for long-running tasks
   - Check server responsiveness

4. **Connection Issues**
   - Verify server process is running
   - Check for permission issues
   - Monitor server logs

### Debug Mode

```ruby
# Enable debug logging
Rails.logger.level = Logger::DEBUG

# Check MCP server status
servers = Rdawn::Tools.list_mcp_servers
servers.each do |server_name|
  puts "Server: #{server_name}"
  puts "Connected: #{Rdawn::MCPManager.instance.server_connected?(server_name)}"
  puts "Tools: #{Rdawn::Tools.list_mcp_server_tools(server_name)}"
end
```

## Conclusion

MCP integration in rdawn provides a powerful way to extend AI workflows with external tools and data sources. By following this guide, you can:

- Set up MCP servers for various data sources
- Create complex workflows that combine MCP tools with LLM tasks
- Handle errors gracefully and optimize performance
- Integrate MCP seamlessly with Rails applications

The standardized MCP protocol ensures compatibility with a growing ecosystem of tools and services, making rdawn a flexible platform for building sophisticated AI applications. 