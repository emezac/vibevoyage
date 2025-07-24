# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::WorkflowEngine do
  let(:workflow) { Rdawn::Workflow.new(workflow_id: '1', name: 'Test Workflow') }
  let(:mock_llm_interface) { double('LLMInterface') }
  let(:engine) { described_class.new(workflow: workflow, llm_interface: mock_llm_interface) }

  describe '#run' do
    context 'with a single task' do
      let(:task1) { Rdawn::Task.new(task_id: '1', name: 'Task 1', input_data: { key: 'value' }) }

      before do
        workflow.add_task(task1)
      end

      it 'executes the task and marks workflow as completed' do
        result = engine.run(initial_input: { user_id: 123 })

        expect(result).to eq(workflow)
        expect(workflow.status).to eq(:completed)
        expect(task1.status).to eq(:completed)
        expect(task1.output_data).to include(
          task_id: '1',
          executed_at: be_a(Time),
          input_processed: { key: 'value' },
          simulated: true
        )
      end

      it 'merges initial input into workflow variables' do
        engine.run(initial_input: { user_id: 123, project_id: 456 })

        expect(workflow.variables).to include(
          user_id: 123,
          project_id: 456
        )
      end

      it 'adds task output to workflow variables' do
        engine.run

        expect(workflow.variables).to include(
          task_id: '1',
          simulated: true
        )
      end
    end

    context 'with sequential tasks' do
      let(:task1) { Rdawn::Task.new(task_id: '1', name: 'Task 1') }
      let(:task2) { Rdawn::Task.new(task_id: '2', name: 'Task 2') }
      let(:task3) { Rdawn::Task.new(task_id: '3', name: 'Task 3') }

      before do
        task1.next_task_id_on_success = '2'
        task2.next_task_id_on_success = '3'
        
        workflow.add_task(task1)
        workflow.add_task(task2)
        workflow.add_task(task3)
      end

      it 'executes tasks in the correct order' do
        execution_order = []
        
        # Override the simulate_task_execution to track execution order
        allow(engine).to receive(:simulate_task_execution) do |task|
          execution_order << task.task_id
          { task_id: task.task_id, executed: true }
        end

        engine.run

        expect(execution_order).to eq(['1', '2', '3'])
        expect(task1.status).to eq(:completed)
        expect(task2.status).to eq(:completed)
        expect(task3.status).to eq(:completed)
        expect(workflow.status).to eq(:completed)
      end

      it 'stops execution if a task fails and has no failure handler' do
        # Make task2 fail
        allow(engine).to receive(:simulate_task_execution) do |task|
          if task.task_id == '2'
            raise StandardError, 'Task 2 failed'
          else
            { task_id: task.task_id, executed: true }
          end
        end

        engine.run

        expect(task1.status).to eq(:completed)
        expect(task2.status).to eq(:failed)
        expect(task3.status).to eq(:pending) # Should not be executed
      end

      it 'handles failure path when next_task_id_on_failure is set' do
        task2.next_task_id_on_failure = '3'
        
        execution_order = []
        
        allow(engine).to receive(:simulate_task_execution) do |task|
          execution_order << task.task_id
          if task.task_id == '2'
            raise StandardError, 'Task 2 failed'
          else
            { task_id: task.task_id, executed: true }
          end
        end

        engine.run

        expect(execution_order).to eq(['1', '2', '3'])
        expect(task1.status).to eq(:completed)
        expect(task2.status).to eq(:failed)
        expect(task3.status).to eq(:completed) # Should be executed via failure path
      end
    end

    context 'with an empty workflow' do
      it 'completes immediately' do
        result = engine.run

        expect(result).to eq(workflow)
        expect(workflow.status).to eq(:completed)
      end
    end

    context 'workflow status tracking' do
      let(:task1) { Rdawn::Task.new(task_id: '1', name: 'Task 1') }

      before do
        workflow.add_task(task1)
      end

      it 'sets workflow status to running at start' do
        expect(workflow.status).to eq(:pending)
        
        allow(engine).to receive(:simulate_task_execution) do |task|
          expect(workflow.status).to eq(:running)
          { executed: true }
        end

        engine.run
      end

      it 'sets workflow status to completed at end' do
        engine.run

        expect(workflow.status).to eq(:completed)
      end
    end

    context 'with variable resolution' do
      let(:task1) { Rdawn::Task.new(task_id: 'task1', name: 'Task 1', input_data: { user_id: 123 }) }
      let(:task2) do
        Rdawn::Task.new(
          task_id: 'task2',
          name: 'Task 2',
          input_data: {
            greeting: 'Hello ${user.name}',
            previous_result: '${task1.result}',
            user_id: '${user_id}'
          }
        )
      end

      before do
        task1.next_task_id_on_success = 'task2'
        workflow.add_task(task1)
        workflow.add_task(task2)
        
        # Mock task1 to return user data
        allow(engine).to receive(:simulate_task_execution) do |task|
          case task.task_id
          when 'task1'
            {
              task_id: 'task1',
              result: 'success',
              user: { name: 'John Doe', email: 'john@example.com' }
            }
          when 'task2'
            # Capture the resolved input data during execution
            resolved_input = task.input_data.dup
            {
              task_id: 'task2',
              resolved_input: resolved_input
            }
          end
        end
      end

      it 'resolves variables in task input_data before execution' do
        workflow.variables['user'] = { name: 'John Doe' }
        
        engine.run(initial_input: { user_id: 123 })

        expect(task2.output_data[:resolved_input]).to eq({
          greeting: 'Hello John Doe',
          previous_result: 'success',
          user_id: 123
        })
      end

      it 'builds context from workflow variables and task outputs' do
        engine.run(initial_input: { user_id: 123, project_id: 456 })

        # Check that task1 output was added to workflow variables
        expect(workflow.variables).to include(
          'task1' => include(
            task_id: 'task1',
            result: 'success',
            user: { name: 'John Doe', email: 'john@example.com' }
          )
        )
      end

      it 'handles nested variable resolution' do
        # Create a separate task2 for this test to avoid interference
        task2_nested = Rdawn::Task.new(
          task_id: 'task2',
          name: 'Task 2',
          input_data: { simple_task: true }
        )
        
        task3 = Rdawn::Task.new(
          task_id: 'task3',
          name: 'Task 3',
          input_data: {
            user_email: '${task1.user.email}',
            user_name: '${task1.user.name}'
          }
        )
        
        task1.next_task_id_on_success = 'task2'
        task2_nested.next_task_id_on_success = 'task3'
        workflow.add_task(task2_nested)
        workflow.add_task(task3)
        
        allow(engine).to receive(:simulate_task_execution) do |task|
          case task.task_id
          when 'task1'
            {
              task_id: 'task1',
              user: { name: 'John Doe', email: 'john@example.com' }
            }
          when 'task2'
            { task_id: 'task2' }
          when 'task3'
            # Capture the resolved input data during execution
            resolved_input = task.input_data.dup
            { task_id: 'task3', resolved_input: resolved_input }
          end
        end

        engine.run

        expect(task3.output_data[:resolved_input]).to eq({
          user_email: 'john@example.com',
          user_name: 'John Doe'
        })
      end
    end

    context 'with conditional logic' do
      let(:task1) { Rdawn::Task.new(task_id: 'task1', name: 'Task 1') }
      let(:task2) { Rdawn::Task.new(task_id: 'task2', name: 'Task 2') }
      let(:task3) { Rdawn::Task.new(task_id: 'task3', name: 'Task 3') }

      before do
        workflow.add_task(task1)
        workflow.add_task(task2)
        workflow.add_task(task3)
        
        allow(engine).to receive(:simulate_task_execution) do |task|
          case task.task_id
          when 'task1'
            { task_id: 'task1', status: 'success', count: 5 }
          when 'task2'
            { task_id: 'task2', executed: true }
          when 'task3'
            { task_id: 'task3', executed: true }
          end
        end
      end

      context 'with string conditions' do
        it 'evaluates true condition and executes next task' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = 'true'
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates false condition and skips next task' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = 'false'
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:pending)
        end

        it 'resolves variables in string conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = '${task1.status}'
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed) # 'success' is truthy
        end
      end

      context 'with hash conditions' do
        it 'evaluates equality conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'eq' => ['${task1.status}', 'success'] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates inequality conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'ne' => ['${task1.status}', 'failure'] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates greater than conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'gt' => ['${task1.count}', 3] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates less than conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'lt' => ['${task1.count}', 10] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates contains conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'contains' => ['${task1.status}', 'succ'] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'evaluates exists conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'exists' => '${task1.status}' }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'skips task when condition is false' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'eq' => ['${task1.status}', 'failure'] }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:pending)
        end
      end

      context 'with proc conditions' do
        it 'evaluates proc conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = proc { |current_task, workflow| 
            current_task.output_data[:status] == 'success' 
          }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
        end

        it 'skips task when proc condition returns false' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = proc { |current_task, workflow| 
            current_task.output_data[:status] == 'failure' 
          }
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:pending)
        end
      end

      context 'with conditional workflow branching' do
        it 'follows different paths based on conditions' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'eq' => ['${task1.status}', 'success'] }
          task2.next_task_id_on_success = 'task3'
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:completed)
          expect(task3.status).to eq(:completed)
        end

        it 'stops execution when condition blocks the path' do
          task1.next_task_id_on_success = 'task2'
          task2.condition = { 'eq' => ['${task1.status}', 'failure'] }
          task2.next_task_id_on_success = 'task3'
          
          engine.run

          expect(task1.status).to eq(:completed)
          expect(task2.status).to eq(:pending)
          expect(task3.status).to eq(:pending)
        end
      end
    end
  end
end 