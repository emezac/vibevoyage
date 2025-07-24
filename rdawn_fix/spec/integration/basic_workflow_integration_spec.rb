# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Basic Workflow Integration Tests' do
  let(:mock_llm_interface) do
    double('LLMInterface').tap do |llm|
      allow(llm).to receive(:execute_llm_call).and_return('Mock LLM response')
    end
  end

  before do
    # Clear any existing tool registrations
    Rdawn::ToolRegistry.instance_variable_set(:@tools, {})
  end

  describe 'Simple DirectHandlerTask Workflow' do
    it 'executes a single DirectHandlerTask successfully' do
      # Create a simple workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'simple_test',
        name: 'Simple Test Workflow'
      )

      # Add a simple task
      task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'simple_task',
        name: 'Simple Task',
        handler: proc do |input_data|
          { message: "Hello, #{input_data[:name]}!", timestamp: Time.now.to_s }
        end
      )

      workflow.add_task(task)

      # Execute workflow
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { name: 'World' })

      # Verify execution
      expect(result).to be_a(Rdawn::Workflow)
      expect(result.status).to eq(:completed)
      expect(result.tasks.count).to eq(1)
      
      task_result = result.tasks['simple_task']
      expect(task_result.status).to eq(:completed)
      expect(task_result.output_data[:handler_result][:message]).to eq('Hello, World!')
      expect(task_result.output_data[:handler_result][:timestamp]).to be_present
    end
  end

  describe 'Sequential Task Workflow' do
    it 'executes multiple DirectHandlerTasks in sequence' do
      # Create workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'sequential_test',
        name: 'Sequential Test Workflow'
      )

      # Task 1: Initialize
      task1 = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'initialize',
        name: 'Initialize Data',
        handler: proc do |input_data|
          { initial_value: 10, multiplier: input_data[:multiplier] || 2 }
        end
      )
      task1.next_task_id_on_success = 'calculate'

      # Task 2: Calculate
      task2 = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'calculate',
        name: 'Calculate Result',
        handler: proc do |input_data, workflow_vars|
          result = workflow_vars[:initial_value] * workflow_vars[:multiplier]
          { calculation: result, operation: 'multiply' }
        end
      )
      task2.next_task_id_on_success = 'finalize'

      # Task 3: Finalize
      task3 = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'finalize',
        name: 'Finalize Result',
        handler: proc do |input_data, workflow_vars|
          {
            final_result: workflow_vars[:calculation],
            operation_performed: workflow_vars[:operation],
            success: true
          }
        end
      )

      workflow.add_task(task1)
      workflow.add_task(task2)
      workflow.add_task(task3)

      # Execute workflow
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { multiplier: 5 })

      # Verify execution
      expect(result.status).to eq(:completed)
      expect(result.tasks.count).to eq(3)

      # Check each task completed
      task1_result = result.tasks['initialize']
      expect(task1_result.status).to eq(:completed)
      expect(task1_result.output_data[:handler_result][:initial_value]).to eq(10)

      task2_result = result.tasks['calculate']
      expect(task2_result.status).to eq(:completed)
      expect(task2_result.output_data[:handler_result][:calculation]).to eq(50) # 10 * 5

      task3_result = result.tasks['finalize']
      expect(task3_result.status).to eq(:completed)
      expect(task3_result.output_data[:handler_result][:final_result]).to eq(50)
      expect(task3_result.output_data[:handler_result][:success]).to be true
    end
  end

  describe 'Tool Registry Integration' do
    it 'executes a tool task successfully' do
      # Register a simple tool
      Rdawn::ToolRegistry.register('simple_formatter', proc do |input|
        text = input[:text] || input['text']
        format = input[:format] || input['format'] || 'uppercase'
        
        formatted_text = case format
                        when 'uppercase' then text.upcase
                        when 'lowercase' then text.downcase
                        else text
                        end
        
        { formatted_text: formatted_text, original_text: text, format_applied: format }
      end)

      # Create workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'tool_test',
        name: 'Tool Test Workflow'
      )

      # Add tool task
      tool_task = Rdawn::Task.new(
        task_id: 'format_text',
        name: 'Format Text',
        tool_name: 'simple_formatter',
        input_data: { text: 'hello world', format: 'uppercase' }
      )

      workflow.add_task(tool_task)

      # Execute workflow
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run

      # Verify execution
      expect(result.status).to eq(:completed)
      
      task_result = result.tasks['format_text']
      expect(task_result.status).to eq(:completed)
      expect(task_result.output_data[:formatted_text]).to eq('HELLO WORLD')
      expect(task_result.output_data[:format_applied]).to eq('uppercase')
    end
  end

  describe 'LLM Task Integration' do
    it 'executes an LLM task successfully' do
      # Create workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'llm_test',
        name: 'LLM Test Workflow'
      )

      # Add LLM task
      llm_task = Rdawn::Task.new(
        task_id: 'generate_text',
        name: 'Generate Text',
        is_llm_task: true,
        input_data: {
          prompt: 'Write a short greeting',
          model_params: { temperature: 0.7 }
        }
      )

      workflow.add_task(llm_task)

      # Execute workflow
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run

      # Verify execution
      expect(result.status).to eq(:completed)
      
      task_result = result.tasks['generate_text']
      expect(task_result.status).to eq(:completed)
      expect(task_result.output_data[:llm_response]).to eq('Mock LLM response')
    end
  end

  describe 'Mixed Task Types Workflow' do
    it 'executes a workflow with DirectHandler, Tool, and LLM tasks' do
      # Register a simple tool
      Rdawn::ToolRegistry.register('data_processor', proc do |input|
        data = input[:data] || input['data']
        { processed_data: "Processed: #{data}", length: data.to_s.length }
      end)

      # Create workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'mixed_test',
        name: 'Mixed Task Types Test'
      )

      # Task 1: DirectHandler - Initialize
      init_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'init',
        name: 'Initialize',
        handler: proc do |input_data|
          { raw_data: "Hello #{input_data[:name]}", initialized: true }
        end
      )
      init_task.next_task_id_on_success = 'process'

      # Task 2: Tool - Process
      process_task = Rdawn::Task.new(
        task_id: 'process',
        name: 'Process Data',
        tool_name: 'data_processor',
        input_data: { data: '${raw_data}' }
      )
      process_task.next_task_id_on_success = 'generate'

      # Task 3: LLM - Generate
      llm_task = Rdawn::Task.new(
        task_id: 'generate',
        name: 'Generate Summary',
        is_llm_task: true,
        input_data: {
          prompt: 'Summarize this data: ${processed_data}',
          model_params: { temperature: 0.5 }
        }
      )

      workflow.add_task(init_task)
      workflow.add_task(process_task)
      workflow.add_task(llm_task)

      # Execute workflow
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { name: 'Test User' })

      # Verify execution
      expect(result.status).to eq(:completed)
      expect(result.tasks.count).to eq(3)

      # Verify each task type worked
      init_result = result.tasks['init']
      expect(init_result.status).to eq(:completed)
      expect(init_result.output_data[:handler_result][:raw_data]).to eq('Hello Test User')

      process_result = result.tasks['process']
      expect(process_result.status).to eq(:completed)
      expect(process_result.output_data[:processed_data]).to eq('Processed: Hello Test User')

      llm_result = result.tasks['generate']
      expect(llm_result.status).to eq(:completed)
      expect(llm_result.output_data[:llm_response]).to eq('Mock LLM response')
    end
  end

  describe 'Error Handling' do
    it 'handles task failures gracefully' do
      # Create workflow
      workflow = Rdawn::Workflow.new(
        workflow_id: 'error_test',
        name: 'Error Handling Test'
      )

      # Task that will fail
      failing_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'failing_task',
        name: 'Failing Task',
        handler: proc do |input_data|
          if input_data[:should_fail]
            raise StandardError, 'Test error'
          end
          { success: true }
        end
      )
      failing_task.next_task_id_on_success = 'success_task'
      failing_task.next_task_id_on_failure = 'error_task'

      # Success task
      success_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'success_task',
        name: 'Success Task',
        handler: proc { { result: 'success_path' } }
      )

      # Error task
      error_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'error_task',
        name: 'Error Task',
        handler: proc { { result: 'error_path', recovered: true } }
      )

      workflow.add_task(failing_task)
      workflow.add_task(success_task)
      workflow.add_task(error_task)

      # Test success path
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { should_fail: false })

      expect(result.status).to eq(:completed)
      success_result = result.tasks['success_task']
      expect(success_result.status).to eq(:completed)
      expect(success_result.output_data[:handler_result][:result]).to eq('success_path')

      # Test error path
      result = agent.run(initial_input: { should_fail: true })

      expect(result.status).to eq(:completed)
      error_result = result.tasks['error_task']
      expect(error_result.status).to eq(:completed)
      expect(error_result.output_data[:handler_result][:result]).to eq('error_path')
      expect(error_result.output_data[:handler_result][:recovered]).to be true
    end
  end
end 