#!/usr/bin/env ruby

require_relative '../../lib/rdawn'

# Simple test to understand the workflow execution
puts "=== Testing Simple Workflow ==="

# Create a simple workflow
workflow = Rdawn::Workflow.new(workflow_id: 'test', name: 'Simple Test')

# Add a simple DirectHandlerTask
task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: 'simple_task',
  name: 'Simple Task',
  handler: proc do |input_data|
    puts "Handler called with: #{input_data.inspect}"
    { result: 'success', input_received: input_data }
  end
)

workflow.add_task(task)

# Create mock LLM interface
mock_llm = Class.new do
  def execute_llm_call(prompt:, model_params: {})
    'Mock response'
  end
end.new

# Create agent and run
agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm)
result = agent.run(initial_input: { test: 'data' })

puts "Result class: #{result.class}"
puts "Result status: #{result.status}"
puts "Result tasks: #{result.tasks.keys}"

task_result = result.tasks['simple_task']
puts "Task status: #{task_result.status}"
puts "Task output: #{task_result.output_data.inspect}"

puts "=== End Simple Test ===" 