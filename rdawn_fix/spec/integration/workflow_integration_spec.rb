# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Workflow Integration Tests' do
  let(:mock_llm_interface) do
    double('LLMInterface').tap do |llm|
      allow(llm).to receive(:execute_llm_call).and_return('Mock LLM response')
    end
  end

  before do
    # Clear any existing tool registrations
    Rdawn::ToolRegistry.instance_variable_set(:@tools, {})
    
    # Register mock tools for testing
    Rdawn::ToolRegistry.register('mock_calculator', proc do |input|
      result = case input[:operation]
               when 'add' then input[:a].to_i + input[:b].to_i
               when 'multiply' then input[:a].to_i * input[:b].to_i
               when 'divide' then input[:a].to_i / input[:b].to_i
               else 0
               end
      { result: result, operation: input[:operation] }
    end)
    
    Rdawn::ToolRegistry.register('mock_data_processor', proc do |input|
      { processed_data: "Processed: #{input[:data]}", count: input[:data].to_s.length }
    end)
  end

  describe 'Complete Sequential Workflow' do
    it 'executes a multi-step workflow with different task types' do
      # Create workflow with multiple task types
      workflow = Rdawn::Workflow.new(
        workflow_id: 'integration_test_1',
        name: 'Complete Integration Test'
      )

      # Task 1: DirectHandler - Initialize data
      init_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'init',
        name: 'Initialize Data',
        handler: proc do |input_data|
          {
            user_id: input_data[:user_id],
            initial_value: 100,
            operations: ['add', 'multiply'],
            timestamp: Time.now.to_s
          }
        end
      )
      init_task.next_task_id_on_success = 'calculate'
      
      # Task 2: Tool - Perform calculation
      calc_task = Rdawn::Task.new(
        task_id: 'calculate',
        name: 'Calculate Result',
        tool_name: 'mock_calculator',
        input_data: {
          a: '${initial_value}',
          b: 50,
          operation: 'add'
        }
      )
      calc_task.next_task_id_on_success = 'process_data'
      
      # Task 3: Tool - Process data
      process_task = Rdawn::Task.new(
        task_id: 'process_data',
        name: 'Process Data',
        tool_name: 'mock_data_processor',
        input_data: {
          data: '${result}'
        }
      )
      process_task.next_task_id_on_success = 'generate_report'
      
      # Task 4: LLM - Generate report
      llm_task = Rdawn::Task.new(
        task_id: 'generate_report',
        name: 'Generate Report',
        is_llm_task: true,
        input_data: {
          prompt: 'Generate a report for user ${user_id} with result ${result} and processed data: ${processed_data}',
          model_params: { temperature: 0.7 }
        }
      )
      
      # Task 5: DirectHandler - Final processing
      final_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'finalize',
        name: 'Finalize Results',
        handler: proc do |input_data, workflow_vars|
          {
            final_report: workflow_vars[:llm_response],
            calculation_result: workflow_vars[:result],
            processed_count: workflow_vars[:count],
            user_id: workflow_vars[:user_id],
            completed_at: Time.now.to_s,
            success: true
          }
        end
      )
      llm_task.next_task_id_on_success = 'finalize'

      # Add tasks to workflow
      workflow.add_task(init_task)
      workflow.add_task(calc_task)
      workflow.add_task(process_task)
      workflow.add_task(llm_task)
      workflow.add_task(final_task)

      # Create and run agent
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { user_id: 'test_user_123' })

      # Verify the complete workflow execution
      expect(result).to be_a(Rdawn::Workflow)
      expect(result.status).to eq(:completed)
      expect(result.workflow_id).to eq('integration_test_1')
      expect(result.tasks.count).to eq(5)
      
      # Verify final task output contains expected data
      final_task = result.tasks['finalize']
      handler_result = final_task.output_data[:handler_result]
      expect(handler_result[:success]).to be true
      expect(handler_result[:user_id]).to eq('test_user_123')
      expect(handler_result[:calculation_result]).to eq(150) # 100 + 50
      expect(handler_result[:processed_count]).to eq(3) # Length of "150"
      expect(handler_result[:final_report]).to eq('Mock LLM response')
      expect(handler_result[:completed_at]).to be_present
    end
  end

  describe 'Error Handling and Recovery' do
    it 'handles task failures and executes failure paths' do
      workflow = Rdawn::Workflow.new(
        workflow_id: 'error_handling_test',
        name: 'Error Handling Test'
      )

      # Task 1: DirectHandler that might fail
      risky_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'risky_operation',
        name: 'Risky Operation',
        handler: proc do |input_data|
          if input_data[:should_fail]
            raise StandardError, 'Simulated failure'
          end
          { success: true, data: 'Operation completed' }
        end
      )
      risky_task.next_task_id_on_success = 'success_handler'
      risky_task.next_task_id_on_failure = 'error_handler'

      # Task 2: Success handler
      success_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'success_handler',
        name: 'Success Handler',
        handler: proc do |input_data, workflow_vars|
          { result: 'Success path executed', original_data: workflow_vars[:data] }
        end
      )

      # Task 3: Error handler
      error_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'error_handler',
        name: 'Error Handler',
        handler: proc do |input_data, workflow_vars|
          { result: 'Error path executed', error_recovered: true }
        end
      )

      workflow.add_task(risky_task)
      workflow.add_task(success_task)
      workflow.add_task(error_task)

      # Test success path
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { should_fail: false })
      
      expect(result.status).to eq(:completed)
      success_task = result.tasks['success_handler']
      expect(success_task.output_data[:handler_result][:result]).to eq('Success path executed')

      # Test error path
      result = agent.run(initial_input: { should_fail: true })
      
      expect(result.status).to eq(:completed)
      error_task = result.tasks['error_handler']
      expect(error_task.output_data[:handler_result][:result]).to eq('Error path executed')
      expect(error_task.output_data[:handler_result][:error_recovered]).to be true
    end
  end

  describe 'Complex Variable Resolution' do
    it 'resolves nested variables and complex data structures' do
      workflow = Rdawn::Workflow.new(
        workflow_id: 'variable_resolution_test',
        name: 'Variable Resolution Test'
      )

      # Task 1: Create complex data structure
      data_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'create_data',
        name: 'Create Complex Data',
        handler: proc do |input_data|
          {
            user: {
              id: input_data[:user_id],
              name: 'John Doe',
              preferences: {
                theme: 'dark',
                notifications: true
              }
            },
            metrics: {
              score: 95,
              level: 'advanced'
            },
            tags: ['important', 'urgent']
          }
        end
      )
      data_task.next_task_id_on_success = 'process_nested'

      # Task 2: Process with nested variable access
      process_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'process_nested',
        name: 'Process Nested Data',
        handler: proc do |input_data, workflow_vars|
          {
            processed_user: "User #{workflow_vars[:user][:name]} (ID: #{workflow_vars[:user][:id]})",
            theme_preference: workflow_vars[:user][:preferences][:theme],
            score_level: "#{workflow_vars[:metrics][:score]} - #{workflow_vars[:metrics][:level]}",
            first_tag: workflow_vars[:tags][0],
            notifications_enabled: workflow_vars[:user][:preferences][:notifications]
          }
        end
      )
      process_task.next_task_id_on_success = 'generate_summary'

      # Task 3: LLM task with complex variable resolution
      llm_task = Rdawn::Task.new(
        task_id: 'generate_summary',
        name: 'Generate Summary',
        is_llm_task: true,
        input_data: {
          prompt: 'Create a summary for ${processed_user} with theme ${theme_preference} and score ${score_level}. First tag: ${first_tag}',
          model_params: { temperature: 0.5 }
        }
      )

      workflow.add_task(data_task)
      workflow.add_task(process_task)
      workflow.add_task(llm_task)

      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run(initial_input: { user_id: 'test_123' })

      expect(result.status).to eq(:completed)
      
      # Verify that nested variables were properly resolved
      process_task = result.tasks['process_nested']
      handler_result = process_task.output_data[:handler_result]
      expect(handler_result[:processed_user]).to eq('User John Doe (ID: test_123)')
      expect(handler_result[:theme_preference]).to eq('dark')
      expect(handler_result[:score_level]).to eq('95 - advanced')
      expect(handler_result[:first_tag]).to eq('important')
      expect(handler_result[:notifications_enabled]).to be true
    end
  end

  describe 'Conditional Execution' do
    it 'executes tasks based on conditions' do
      workflow = Rdawn::Workflow.new(
        workflow_id: 'conditional_test',
        name: 'Conditional Execution Test'
      )

      # Task 1: Initialize with user type
      init_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'init_user',
        name: 'Initialize User',
        handler: proc do |input_data|
          {
            user_type: input_data[:user_type],
            account_balance: input_data[:balance] || 0
          }
        end
      )
      init_task.next_task_id_on_success = 'check_premium'

      # Task 2: Premium user check (conditional)
      premium_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'check_premium',
        name: 'Premium Features',
        handler: proc do |input_data, workflow_vars|
          { premium_features: ['advanced_analytics', 'priority_support'] }
        end
      )
      premium_task.condition = proc { |workflow_vars| workflow_vars[:user_type] == 'premium' }
      premium_task.next_task_id_on_success = 'finalize_user'

      # Task 3: Regular user check (conditional)
      regular_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'check_regular',
        name: 'Regular Features',
        handler: proc do |input_data, workflow_vars|
          { regular_features: ['basic_analytics'] }
        end
      )
      regular_task.condition = proc { |workflow_vars| workflow_vars[:user_type] == 'regular' }
      regular_task.next_task_id_on_success = 'finalize_user'

      # Task 4: Finalize
      final_task = Rdawn::Tasks::DirectHandlerTask.new(
        task_id: 'finalize_user',
        name: 'Finalize User Setup',
        handler: proc do |input_data, workflow_vars|
          features = workflow_vars[:premium_features] || workflow_vars[:regular_features] || []
          {
            user_type: workflow_vars[:user_type],
            available_features: features,
            setup_complete: true
          }
        end
      )

      # Set up alternative paths
      init_task.next_task_id_on_success = 'check_premium'
      premium_task.next_task_id_on_success = 'finalize_user'
      regular_task.next_task_id_on_success = 'finalize_user'

      workflow.add_task(init_task)
      workflow.add_task(premium_task)
      workflow.add_task(regular_task)
      workflow.add_task(final_task)

      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)

      # Test premium user path
      result = agent.run(initial_input: { user_type: 'premium' })
      final_task = result.tasks['finalize_user']
      handler_result = final_task.output_data[:handler_result]
      expect(handler_result[:available_features]).to include('advanced_analytics')
      
      # Test regular user path
      result = agent.run(initial_input: { user_type: 'regular' })
      final_task = result.tasks['finalize_user']
      handler_result = final_task.output_data[:handler_result]
      expect(handler_result[:available_features]).to include('basic_analytics')
      expect(handler_result[:available_features]).not_to include('advanced_analytics')
    end
  end

  describe 'Tool Registry Integration' do
    it 'works with dynamically registered tools' do
      # Register a new tool dynamically
      Rdawn::ToolRegistry.register('dynamic_formatter', proc do |input|
        format_type = input[:format] || 'default'
        data = input[:data]
        
        formatted = case format_type
                   when 'uppercase' then data.to_s.upcase
                   when 'lowercase' then data.to_s.downcase
                   when 'title' then data.to_s.titleize
                   else data.to_s
                   end
        
        { formatted_data: formatted, format_applied: format_type }
      end)

      workflow = Rdawn::Workflow.new(
        workflow_id: 'tool_registry_test',
        name: 'Tool Registry Test'
      )

      format_task = Rdawn::Task.new(
        task_id: 'format_data',
        name: 'Format Data',
        tool_name: 'dynamic_formatter',
        input_data: {
          data: 'hello world from rdawn',
          format: 'uppercase'
        }
      )

      workflow.add_task(format_task)

      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      result = agent.run

      format_task = result.tasks['format_data']
      # Tool tasks have direct output_data structure
      expect(format_task.output_data[:formatted_data]).to eq('HELLO WORLD FROM RDAWN')
      expect(format_task.output_data[:format_applied]).to eq('uppercase')
    end
  end

  describe 'Performance and Scalability' do
    it 'handles workflows with many tasks efficiently' do
      workflow = Rdawn::Workflow.new(
        workflow_id: 'performance_test',
        name: 'Performance Test'
      )

      # Create a chain of 20 tasks
      (1..20).each do |i|
        task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: "task_#{i}",
          name: "Task #{i}",
          handler: proc do |input_data, workflow_vars|
            { 
              step: i,
              accumulated_value: (workflow_vars[:accumulated_value] || 0) + i,
              timestamp: Time.now.to_f
            }
          end
        )
        task.next_task_id_on_success = "task_#{i + 1}" if i < 20
        workflow.add_task(task)
      end

      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
      
      start_time = Time.now
      result = agent.run
      execution_time = Time.now - start_time

      expect(result.status).to eq(:completed)
      expect(result.tasks.count).to eq(20)
      final_task = result.tasks['task_20']
      handler_result = final_task.output_data[:handler_result]
      expect(handler_result[:accumulated_value]).to eq(210) # Sum of 1 to 20
      expect(execution_time).to be < 5.0 # Should complete in under 5 seconds
    end
  end
end 