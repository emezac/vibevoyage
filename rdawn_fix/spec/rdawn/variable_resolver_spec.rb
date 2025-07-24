# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::VariableResolver do
  describe '.resolve' do
    let(:context) do
      {
        'user' => {
          'name' => 'John Doe',
          'email' => 'john@example.com',
          'profile' => {
            'age' => 30,
            'active' => true
          }
        },
        'task1' => {
          'output' => {
            'result' => 'success',
            'data' => { 'id' => 123, 'count' => 5 }
          }
        },
        'simple_string' => 'hello world',
        'number' => 42,
        'boolean' => true,
        'null_value' => nil
      }
    end

    context 'with nil input' do
      it 'returns nil' do
        expect(described_class.resolve(nil, context)).to be_nil
      end
    end

    context 'with non-string data' do
      it 'returns numbers unchanged' do
        expect(described_class.resolve(42, context)).to eq(42)
      end

      it 'returns booleans unchanged' do
        expect(described_class.resolve(true, context)).to eq(true)
        expect(described_class.resolve(false, context)).to eq(false)
      end
    end

    context 'with string variables' do
      it 'resolves simple variable references' do
        result = described_class.resolve('${simple_string}', context)
        expect(result).to eq('hello world')
      end

      it 'resolves nested hash access' do
        result = described_class.resolve('${user.name}', context)
        expect(result).to eq('John Doe')
      end

      it 'resolves deeply nested hash access' do
        result = described_class.resolve('${user.profile.age}', context)
        expect(result).to eq(30)
      end

      it 'resolves complex nested paths' do
        result = described_class.resolve('${task1.output.data.id}', context)
        expect(result).to eq(123)
      end

      it 'preserves original data type for direct variable references' do
        result = described_class.resolve('${number}', context)
        expect(result).to eq(42)
        expect(result).to be_a(Integer)

        result = described_class.resolve('${boolean}', context)
        expect(result).to eq(true)
        expect(result).to be_a(TrueClass)
      end

      it 'interpolates variables within strings' do
        result = described_class.resolve('Hello ${user.name}!', context)
        expect(result).to eq('Hello John Doe!')
      end

      it 'handles multiple variables in one string' do
        result = described_class.resolve('${user.name} (${user.email})', context)
        expect(result).to eq('John Doe (john@example.com)')
      end

      it 'returns string unchanged when no variables present' do
        result = described_class.resolve('plain string', context)
        expect(result).to eq('plain string')
      end
    end

    context 'with hash data' do
      it 'resolves variables in hash values' do
        input = {
          'greeting' => 'Hello ${user.name}',
          'age' => '${user.profile.age}',
          'static' => 'unchanged'
        }

        result = described_class.resolve(input, context)
        expect(result).to eq({
          'greeting' => 'Hello John Doe',
          'age' => 30,
          'static' => 'unchanged'
        })
      end

      it 'resolves nested hash structures' do
        input = {
          'user_info' => {
            'name' => '${user.name}',
            'contact' => '${user.email}'
          },
          'metadata' => {
            'count' => '${task1.output.data.count}'
          }
        }

        result = described_class.resolve(input, context)
        expect(result).to eq({
          'user_info' => {
            'name' => 'John Doe',
            'contact' => 'john@example.com'
          },
          'metadata' => {
            'count' => 5
          }
        })
      end
    end

    context 'with array data' do
      it 'resolves variables in array elements' do
        input = ['${user.name}', '${user.email}', 'static']
        result = described_class.resolve(input, context)
        expect(result).to eq(['John Doe', 'john@example.com', 'static'])
      end

      it 'resolves variables in nested array structures' do
        input = [
          { 'name' => '${user.name}' },
          ['${user.email}', '${simple_string}']
        ]

        result = described_class.resolve(input, context)
        expect(result).to eq([
          { 'name' => 'John Doe' },
          ['john@example.com', 'hello world']
        ])
      end
    end

    context 'with symbol keys in context' do
      let(:symbol_context) do
        {
          user: {
            name: 'Jane Doe',
            email: 'jane@example.com'
          }
        }
      end

      it 'resolves variables using symbol keys' do
        result = described_class.resolve('${user.name}', symbol_context)
        expect(result).to eq('Jane Doe')
      end
    end

    context 'with mixed string and symbol keys' do
      let(:mixed_context) do
        {
          'user' => {
            name: 'Mixed Keys',
            'email' => 'mixed@example.com'
          }
        }
      end

      it 'resolves variables with mixed key types' do
        result = described_class.resolve('${user.name}', mixed_context)
        expect(result).to eq('Mixed Keys')

        result = described_class.resolve('${user.email}', mixed_context)
        expect(result).to eq('mixed@example.com')
      end
    end

    context 'with object methods' do
      let(:object_context) do
        user = double('User')
        allow(user).to receive(:name).and_return('Object User')
        allow(user).to receive(:email).and_return('object@example.com')
        { 'user' => user }
      end

      it 'resolves variables by calling object methods' do
        result = described_class.resolve('${user.name}', object_context)
        expect(result).to eq('Object User')
      end
    end

    context 'error handling' do
      it 'raises VariableResolutionError for non-existent keys' do
        expect {
          described_class.resolve('${nonexistent}', context)
        }.to raise_error(Rdawn::Errors::VariableResolutionError, /Cannot resolve 'nonexistent'/)
      end

      it 'raises VariableResolutionError for non-existent nested keys' do
        expect {
          described_class.resolve('${user.nonexistent}', context)
        }.to raise_error(Rdawn::Errors::VariableResolutionError, /Cannot resolve 'nonexistent'/)
      end

      it 'raises VariableResolutionError for invalid path navigation' do
        expect {
          described_class.resolve('${simple_string.nonexistent}', context)
        }.to raise_error(Rdawn::Errors::VariableResolutionError, /Cannot resolve 'nonexistent'/)
      end

      it 'raises VariableResolutionError for method call failures' do
        object = double('Object')
        allow(object).to receive(:respond_to?).with('invalid_method').and_return(true)
        allow(object).to receive(:public_send).with('invalid_method').and_raise(NoMethodError, 'Method not found')
        
        context_with_object = { 'obj' => object }
        
        expect {
          described_class.resolve('${obj.invalid_method}', context_with_object)
        }.to raise_error(Rdawn::Errors::VariableResolutionError, /Failed to resolve variable path/)
      end
    end

    context 'edge cases' do
      it 'handles empty variable references' do
        expect {
          described_class.resolve('${}', context)
        }.to raise_error(Rdawn::Errors::VariableResolutionError)
      end

      it 'handles whitespace in variable references' do
        result = described_class.resolve('${ user.name }', context)
        expect(result).to eq('John Doe')
      end

      it 'handles null values' do
        result = described_class.resolve('${null_value}', context)
        expect(result).to be_nil
      end

      it 'handles multiple variable references with same variable' do
        result = described_class.resolve('${user.name} and ${user.name}', context)
        expect(result).to eq('John Doe and John Doe')
      end
    end
  end
end 