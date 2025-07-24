# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::ToolRegistry do
  let(:registry) { described_class.instance }

  before do
    # Clear registry before each test
    registry.clear_all
  end

  describe '#register' do
    it 'registers a Proc tool' do
      tool = proc { |data| "Processed: #{data}" }
      
      registry.register('proc_tool', tool)
      
      expect(registry.tool_exists?('proc_tool')).to be true
      expect(registry.registered_tools).to include('proc_tool')
    end

    it 'registers a Method tool' do
      def sample_method(data)
        "Method result: #{data}"
      end
      
      tool = method(:sample_method)
      registry.register('method_tool', tool)
      
      expect(registry.tool_exists?('method_tool')).to be true
    end

    it 'registers a Class tool' do
      class TestTool
        def execute(data)
          "Class result: #{data}"
        end
      end
      
      registry.register('class_tool', TestTool)
      
      expect(registry.tool_exists?('class_tool')).to be true
    end

    it 'registers an object with execute method' do
      tool_object = Object.new
      def tool_object.execute(data)
        "Object result: #{data}"
      end
      
      registry.register('object_tool', tool_object)
      
      expect(registry.tool_exists?('object_tool')).to be true
    end

    it 'raises error for nil tool name' do
      expect {
        registry.register(nil, proc { 'test' })
      }.to raise_error(ArgumentError, 'Tool name cannot be nil')
    end

    it 'raises error for empty tool name' do
      expect {
        registry.register('', proc { 'test' })
      }.to raise_error(ArgumentError, 'Tool name cannot be empty')
    end

    it 'raises error for nil tool object' do
      expect {
        registry.register('test', nil)
      }.to raise_error(ArgumentError, 'Tool object cannot be nil')
    end

    it 'raises error for invalid tool object' do
      expect {
        registry.register('test', 'not_a_tool')
      }.to raise_error(ArgumentError, 'Tool must be a Proc, Method, Class, or respond to :execute')
    end
  end

  describe '#execute' do
    context 'with Proc tools' do
      it 'executes Proc with no arguments' do
        tool = proc { 'No args result' }
        registry.register('no_args_proc', tool)
        
        result = registry.execute('no_args_proc')
        
        expect(result).to eq('No args result')
      end

      it 'executes Proc with input data' do
        tool = proc { |data| "Data: #{data[:value]}" }
        registry.register('proc_with_data', tool)
        
        result = registry.execute('proc_with_data', { value: 'test' })
        
        expect(result).to eq('Data: test')
      end

      it 'executes Proc with keyword arguments' do
        tool = proc { |name:, age:| "#{name} is #{age} years old" }
        registry.register('proc_with_kwargs', tool)
        
        result = registry.execute('proc_with_kwargs', { name: 'John', age: 30 })
        
        expect(result).to eq('John is 30 years old')
      end
    end

    context 'with Method tools' do
      before do
        def sample_method(data)
          "Method: #{data[:message]}"
        end
      end

      it 'executes Method tool' do
        registry.register('method_tool', method(:sample_method))
        
        result = registry.execute('method_tool', { message: 'hello' })
        
        expect(result).to eq('Method: hello')
      end
    end

    context 'with Class tools' do
      it 'executes Class tool with no arguments' do
        class NoArgsClassTool
          def execute
            'Class executed'
          end
        end
        
        registry.register('no_args_class', NoArgsClassTool)
        
        result = registry.execute('no_args_class')
        
        expect(result).to eq('Class executed')
      end

      it 'executes Class tool with input data' do
        class ClassToolWithData
          def execute(data)
            "Class processed: #{data[:input]}"
          end
        end
        
        registry.register('class_with_data', ClassToolWithData)
        
        result = registry.execute('class_with_data', { input: 'test_data' })
        
        expect(result).to eq('Class processed: test_data')
      end

      it 'raises error for Class without execute method' do
        class InvalidClassTool
          def process(data)
            data
          end
        end
        
        registry.register('invalid_class', InvalidClassTool)
        
        expect {
          registry.execute('invalid_class')
        }.to raise_error(Rdawn::Errors::TaskExecutionError)
      end
    end

    context 'with object tools' do
      it 'executes object tool with no arguments' do
        tool_object = Object.new
        def tool_object.execute
          'Object executed'
        end
        
        registry.register('object_no_args', tool_object)
        
        result = registry.execute('object_no_args')
        
        expect(result).to eq('Object executed')
      end

      it 'executes object tool with input data' do
        tool_object = Object.new
        def tool_object.execute(data)
          "Object: #{data[:key]}"
        end
        
        registry.register('object_with_data', tool_object)
        
        result = registry.execute('object_with_data', { key: 'value' })
        
        expect(result).to eq('Object: value')
      end
    end

    context 'error handling' do
      it 'raises ToolNotFoundError for non-existent tool' do
        expect {
          registry.execute('non_existent_tool')
        }.to raise_error(Rdawn::Errors::ToolNotFoundError, "Tool 'non_existent_tool' not found")
      end

      it 'raises TaskExecutionError when tool execution fails' do
        failing_tool = proc { raise StandardError, 'Tool error' }
        registry.register('failing_tool', failing_tool)
        
        expect {
          registry.execute('failing_tool')
        }.to raise_error(Rdawn::Errors::TaskExecutionError, "Tool 'failing_tool' execution failed: Tool error")
      end
    end
  end

  describe '#unregister' do
    it 'removes a registered tool' do
      tool = proc { 'test' }
      registry.register('test_tool', tool)
      
      expect(registry.tool_exists?('test_tool')).to be true
      
      registry.unregister('test_tool')
      
      expect(registry.tool_exists?('test_tool')).to be false
    end
  end

  describe '#clear_all' do
    it 'removes all registered tools' do
      registry.register('tool1', proc { 'test1' })
      registry.register('tool2', proc { 'test2' })
      
      expect(registry.registered_tools.length).to eq(2)
      
      registry.clear_all
      
      expect(registry.registered_tools).to be_empty
    end
  end

  describe 'class methods' do
    after do
      described_class.clear_all
    end

    it 'provides class method access to instance methods' do
      tool = proc { 'class method test' }
      
      described_class.register('class_test', tool)
      
      expect(described_class.tool_exists?('class_test')).to be true
      expect(described_class.registered_tools).to include('class_test')
      
      result = described_class.execute('class_test')
      expect(result).to eq('class method test')
      
      described_class.unregister('class_test')
      expect(described_class.tool_exists?('class_test')).to be false
    end
  end
end 