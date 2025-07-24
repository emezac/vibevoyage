# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::Tasks::DirectHandlerTask do
  describe '#initialize' do
    it 'initializes with valid Proc handler' do
      handler = proc { |data| "Processed: #{data}" }
      
      task = described_class.new(
        task_id: '1',
        name: 'Test Task',
        handler: handler,
        input_data: { key: 'value' }
      )
      
      expect(task.task_id).to eq('1')
      expect(task.name).to eq('Test Task')
      expect(task.handler).to eq(handler)
      expect(task.input_data).to eq({ key: 'value' })
      expect(task.status).to eq(:pending)
    end

    it 'initializes with valid lambda handler' do
      handler = lambda { |data| "Processed: #{data}" }
      
      task = described_class.new(
        task_id: '1',
        name: 'Test Task',
        handler: handler
      )
      
      expect(task.handler).to eq(handler)
    end

    it 'initializes with callable object handler' do
      handler = Object.new
      def handler.call(data)
        "Called with: #{data}"
      end
      
      task = described_class.new(
        task_id: '1',
        name: 'Test Task',
        handler: handler
      )
      
      expect(task.handler).to eq(handler)
    end

    it 'raises error with invalid handler (non-callable)' do
      expect {
        described_class.new(
          task_id: '1',
          name: 'Test Task',
          handler: 'not_callable'
        )
      }.to raise_error(ArgumentError, 'Handler must be a Proc, lambda, or respond to :call')
    end

    it 'raises error with nil handler' do
      expect {
        described_class.new(
          task_id: '1',
          name: 'Test Task',
          handler: nil
        )
      }.to raise_error(ArgumentError, 'Handler must be a Proc, lambda, or respond to :call')
    end
  end

  describe '#to_h' do
    it 'includes handler description for Proc' do
      handler = proc { |data| data }
      task = described_class.new(task_id: '1', name: 'Test', handler: handler)
      
      hash = task.to_h
      
      expect(hash[:task_type]).to eq('direct_handler')
      expect(hash[:handler]).to include('Proc with')
    end

    it 'includes handler description for lambda' do
      handler = lambda { |data| data }
      task = described_class.new(task_id: '1', name: 'Test', handler: handler)
      
      hash = task.to_h
      
      expect(hash[:task_type]).to eq('direct_handler')
      expect(hash[:handler]).to include('Lambda with')
    end

    it 'includes handler description for callable object' do
      handler = Object.new
      def handler.call(data); data; end
      
      task = described_class.new(task_id: '1', name: 'Test', handler: handler)
      
      hash = task.to_h
      
      expect(hash[:task_type]).to eq('direct_handler')
      expect(hash[:handler]).to include('Callable object')
    end
  end

  describe 'handler execution patterns' do
    let(:workflow) { Rdawn::Workflow.new(workflow_id: '1', name: 'Test Workflow') }
    let(:mock_llm_interface) { double('LLMInterface') }
    let(:engine) { Rdawn::WorkflowEngine.new(workflow: workflow, llm_interface: mock_llm_interface) }

    context 'with no parameter handler' do
      it 'executes handler with no parameters' do
        executed = false
        handler = proc { executed = true; 'no params result' }
        
        task = described_class.new(task_id: '1', name: 'Test', handler: handler)
        workflow.add_task(task)
        
        result = engine.run
        
        expect(executed).to be true
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('no params result')
      end
    end

    context 'with single parameter handler' do
      it 'executes handler with input data' do
        handler = proc { |data| "Input: #{data[:message]}" }
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { message: 'hello' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('Input: hello')
      end
    end

    context 'with two parameter handler' do
      it 'executes handler with input data and workflow variables' do
        handler = proc do |input_data, workflow_vars|
          "Input: #{input_data[:message]}, Vars: #{workflow_vars[:user_id]}"
        end
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { message: 'hello' }
        )
        workflow.add_task(task)
        
        result = engine.run(initial_input: { user_id: 123 })
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('Input: hello, Vars: 123')
      end
    end

    context 'with keyword argument handler' do
      it 'executes handler with keyword arguments from input data' do
        handler = proc { |message:| "Message: #{message}" }
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { message: 'hello world' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('Message: hello world')
      end

      it 'executes handler with keyword arguments from workflow variables' do
        handler = proc { |user_id:, message:| "User #{user_id}: #{message}" }
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { message: 'hello' }
        )
        workflow.add_task(task)
        
        result = engine.run(initial_input: { user_id: 123 })
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('User 123: hello')
      end
    end

    context 'with lambda handler' do
      it 'executes lambda with strict arity checking' do
        handler = lambda { |data| "Lambda: #{data[:value]}" }
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { value: 'test' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('Lambda: test')
      end
    end

    context 'with callable object handler' do
      it 'executes callable object' do
        handler = Object.new
        def handler.call(data)
          "Object called with: #{data[:input]}"
        end
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { input: 'test data' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:completed)
        expect(task.output_data[:handler_result]).to eq('Object called with: test data')
      end
    end

    context 'error handling' do
      it 'marks task as failed when handler raises error' do
        handler = proc { raise StandardError, 'Handler error' }
        
        task = described_class.new(task_id: '1', name: 'Test', handler: handler)
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:failed)
        expect(task.output_data[:error]).to eq('Handler error')
      end

      it 'handles argument errors gracefully' do
        # Lambda with strict arity checking - requires exactly 0 arguments
        handler = lambda { "No arguments expected" }
        
        # Override the execute_handler method to force it to call with arguments
        allow(engine).to receive(:execute_handler) do |h, input_data, workflow_vars|
          h.call(input_data) # This should fail because lambda expects 0 args
        end
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { some_param: 'value' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        expect(task.status).to eq(:failed)
        expect(task.output_data[:error]).to include('wrong number of arguments')
      end
    end

    context 'output data structure' do
      it 'includes proper metadata in output' do
        handler = proc { |data| "Result: #{data[:value]}" }
        
        task = described_class.new(
          task_id: '1',
          name: 'Test',
          handler: handler,
          input_data: { value: 'test' }
        )
        workflow.add_task(task)
        
        result = engine.run
        
        output = task.output_data
        expect(output[:task_id]).to eq('1')
        expect(output[:executed_at]).to be_a(Time)
        expect(output[:input_processed]).to eq({ value: 'test' })
        expect(output[:handler_result]).to eq('Result: test')
        expect(output[:handler_info]).to include('Proc with')
        expect(output[:type]).to eq(:direct_handler_task)
      end
    end
  end
end 