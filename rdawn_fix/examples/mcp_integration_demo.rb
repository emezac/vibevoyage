#!/usr/bin/env ruby
# frozen_string_literal: true

# MCP Integration Demo for rdawn
# This demonstrates how to integrate MCP servers with rdawn workflows

require 'rdawn'

puts "🚀 Rdawn MCP Integration Demo"
puts "=" * 50

# Example 1: Register MCP Servers
puts "\n1. Registering MCP Servers"
puts "-" * 30

# Register a filesystem MCP server
filesystem_config = {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
  env: {},
  timeout: 30,
  auto_register_tools: true
}

begin
  Rdawn::Tools.register_mcp_server('filesystem', filesystem_config)
  puts "✅ Filesystem MCP server registered"
rescue => e
  puts "❌ Failed to register filesystem server: #{e.message}"
end

# Register a SQLite MCP server
sqlite_config = {
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-sqlite', '/tmp/test.db'],
  env: {},
  timeout: 30,
  auto_register_tools: true
}

begin
  Rdawn::Tools.register_mcp_server('sqlite', sqlite_config)
  puts "✅ SQLite MCP server registered"
rescue => e
  puts "❌ Failed to register SQLite server: #{e.message}"
end

# Example 2: List Available MCP Servers and Tools
puts "\n2. Available MCP Servers and Tools"
puts "-" * 30

servers = Rdawn::Tools.list_mcp_servers
puts "Registered MCP servers: #{servers.join(', ')}"

servers.each do |server_name|
  begin
    tools = Rdawn::Tools.list_mcp_server_tools(server_name)
    puts "  #{server_name}: #{tools.join(', ')}"
  rescue => e
    puts "  #{server_name}: Error - #{e.message}"
  end
end

# Example 3: Create MCP Tasks
puts "\n3. Creating MCP Tasks"
puts "-" * 30

# Create a simple MCP task
mcp_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'mcp_list_files',
  name: 'List Files with MCP',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'list_directory',
  input_data: { path: '/tmp' },
  async_execution: false
)

puts "Created MCP task: #{mcp_task.task_description}"
puts "Task configuration: #{mcp_task.to_h}"

# Example 4: Build a Workflow with MCP Tasks
puts "\n4. Building Workflow with MCP Tasks"
puts "-" * 30

workflow = Rdawn::Workflow.new(
  workflow_id: 'mcp_demo_workflow',
  name: 'MCP Demo Workflow'
)

# Task 1: List files in directory
list_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'list_files',
  name: 'List Files',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'list_directory',
  input_data: { path: '/tmp' },
  next_task_id_on_success: 'read_file'
)

# Task 2: Read a specific file (example)
read_task = Rdawn::Tasks::MCPTask.new(
  task_id: 'read_file',
  name: 'Read File',
  mcp_server_name: 'filesystem',
  mcp_tool_name: 'read_file',
  input_data: { path: '/tmp/example.txt' },
  next_task_id_on_success: 'analyze_content'
)

# Task 3: Analyze content with LLM
analyze_task = Rdawn::Task.new(
  task_id: 'analyze_content',
  name: 'Analyze Content',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this file content: ${read_file.mcp_result}',
    model_params: { temperature: 0.3, max_tokens: 500 }
  }
)

# Add tasks to workflow
workflow.add_task(list_task)
workflow.add_task(read_task)
workflow.add_task(analyze_task)

puts "Workflow created with #{workflow.tasks.size} tasks"

# Example 5: Execute MCP Tools Directly
puts "\n5. Direct MCP Tool Execution"
puts "-" * 30

# Example of direct tool execution
begin
  result = Rdawn::Tools.execute_mcp_tool(
    'filesystem',
    'list_directory',
    { path: '/tmp' }
  )
  puts "Direct MCP tool result: #{result}"
rescue => e
  puts "❌ Direct tool execution failed: #{e.message}"
end

# Example of async tool execution
begin
  future = Rdawn::Tools.execute_mcp_tool_async(
    'filesystem',
    'list_directory',
    { path: '/tmp' }
  )
  puts "Async MCP tool started, waiting for result..."
  result = future.value!(10) # Wait up to 10 seconds
  puts "Async MCP tool result: #{result}"
rescue => e
  puts "❌ Async tool execution failed: #{e.message}"
end

# Example 6: Using MCP Tools in ToolRegistry
puts "\n6. MCP Tools in ToolRegistry"
puts "-" * 30

# List all registered tools (including MCP tools)
all_tools = Rdawn::ToolRegistry.registered_tools
mcp_tools = all_tools.select { |tool| tool.start_with?('mcp_') }

puts "MCP tools registered in ToolRegistry:"
mcp_tools.each do |tool_name|
  puts "  - #{tool_name}"
end

# Execute an MCP tool via ToolRegistry
if mcp_tools.any?
  tool_name = mcp_tools.first
  begin
    result = Rdawn::ToolRegistry.execute(tool_name, { path: '/tmp' })
    puts "ToolRegistry MCP execution result: #{result}"
  rescue => e
    puts "❌ ToolRegistry MCP execution failed: #{e.message}"
  end
end

# Example 7: Multi-Server MCP Workflow
puts "\n7. Multi-Server MCP Workflow"
puts "-" * 30

multi_server_config = {
  'filesystem' => {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp']
  },
  'web_search' => {
    command: 'python',
    args: ['./mcp_servers/web_search.py']
  }
}

begin
  workflow_info = Rdawn::Tools.create_mcp_workflow(
    server_configs: multi_server_config,
    workflow_name: 'Multi-Server Demo'
  )
  puts "Multi-server workflow created:"
  puts "  - Workflow name: #{workflow_info[:workflow_name]}"
  puts "  - Registered servers: #{workflow_info[:registered_servers].join(', ')}"
  puts "  - Available tools: #{workflow_info[:available_tools]}"
rescue => e
  puts "❌ Multi-server workflow creation failed: #{e.message}"
end

# Example 8: Rails Integration Example
puts "\n8. Rails Integration Example"
puts "-" * 30

rails_workflow_data = {
  workflow_id: 'mcp_rails_demo',
  name: 'MCP Rails Demo Workflow',
  tasks: {
    'setup_mcp' => {
      type: 'direct_handler',
      name: 'Setup MCP Servers',
      handler: 'MCPSetupHandler#setup_servers',
      input_data: {},
      next_task_id_on_success: 'list_files'
    },
    'list_files' => {
      type: 'mcp',
      name: 'List Project Files',
      mcp_server_name: 'filesystem',
      mcp_tool_name: 'list_directory',
      input_data: { path: '${project_path}' },
      next_task_id_on_success: 'analyze_structure'
    },
    'analyze_structure' => {
      type: 'llm',
      name: 'Analyze Project Structure',
      input_data: {
        prompt: 'Analyze this project structure: ${list_files.mcp_result}',
        model_params: { temperature: 0.3 }
      },
      next_task_id_on_success: 'save_analysis'
    },
    'save_analysis' => {
      type: 'direct_handler',
      name: 'Save Analysis Results',
      handler: 'AnalysisHandler#save_results',
      input_data: {
        analysis: '${analyze_structure.llm_response}',
        project_path: '${project_path}'
      }
    }
  }
}

puts "Rails workflow configuration:"
puts JSON.pretty_generate(rails_workflow_data)

# Example 9: Error Handling and Recovery
puts "\n9. Error Handling and Recovery"
puts "-" * 30

begin
  # Try to execute a tool that might fail
  result = Rdawn::Tools.execute_mcp_tool(
    'nonexistent_server',
    'nonexistent_tool',
    {}
  )
rescue Rdawn::Errors::ToolNotFoundError => e
  puts "❌ Tool not found error: #{e.message}"
rescue Rdawn::Errors::TaskExecutionError => e
  puts "❌ Task execution error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
end

# Example 10: Configuration and Best Practices
puts "\n10. Configuration and Best Practices"
puts "-" * 30

puts "MCP Integration Best Practices:"
puts "1. Always use timeouts for MCP operations"
puts "2. Use async execution for long-running tasks"
puts "3. Implement proper error handling"
puts "4. Register servers at application startup"
puts "5. Use meaningful server and tool names"
puts "6. Monitor server health and connectivity"
puts "7. Clean up resources on shutdown"

# Cleanup
puts "\n🧹 Cleanup"
puts "-" * 30

begin
  Rdawn::Tools.shutdown_mcp
  puts "✅ MCP servers shut down successfully"
rescue => e
  puts "❌ Shutdown failed: #{e.message}"
end

puts "\n✅ MCP Integration Demo Complete!"
puts "=" * 50 