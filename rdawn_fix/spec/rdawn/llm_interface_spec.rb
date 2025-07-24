# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::LLMInterface do
  let(:api_key) { 'test-api-key' }
  let(:model) { 'anthropic/claude-3.5-sonnet' }
  let(:llm_interface) { described_class.new(api_key: api_key, model: model) }
  
  describe '#initialize' do
    it 'initializes with provided configuration' do
      interface = described_class.new(
        provider: :open_router,
        api_key: 'test-key',
        model: 'test-model'
      )
      
      expect(interface.instance_variable_get(:@provider)).to eq(:open_router)
      expect(interface.instance_variable_get(:@api_key)).to eq('test-key')
      expect(interface.instance_variable_get(:@model)).to eq('test-model')
    end

    it 'uses environment variable for API key when not provided' do
      allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return('env-api-key')
      
      interface = described_class.new(model: 'test-model')
      
      expect(interface.instance_variable_get(:@api_key)).to eq('env-api-key')
    end

    it 'uses default model when not provided' do
      interface = described_class.new(api_key: 'test-key')
      
      expect(interface.instance_variable_get(:@model)).to eq('anthropic/claude-3.5-sonnet')
    end

    it 'raises error when API key is missing' do
      allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return(nil)
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      allow(ENV).to receive(:[]).with('RDAWN_LLM_API_KEY').and_return(nil)
      
      expect {
        described_class.new(model: 'test-model')
      }.to raise_error(Rdawn::Errors::ConfigurationError, 'API key is required')
    end

    it 'raises error when model is missing' do
      expect {
        described_class.new(api_key: 'test-key', model: '')
      }.to raise_error(Rdawn::Errors::ConfigurationError, 'Model is required')
    end
  end

  describe '#execute_llm_call' do
    let(:mock_client) { double('Raix::Client') }
    let(:mock_response) { { 'choices' => [{ 'message' => { 'content' => 'Test response' } }] } }

    before do
      allow(llm_interface).to receive(:chat_completion).and_return('Test response')
    end

    context 'with string prompt' do
      it 'executes LLM call successfully' do
        prompt = 'Hello, world!'
        
        result = llm_interface.execute_llm_call(prompt: prompt)
        
        expect(result).to eq('Test response')
        expect(llm_interface).to have_received(:chat_completion).with(
          params: hash_including(
            model: model,
            temperature: 0.7,
            max_tokens: 1000
          )
        )
      end
    end

    context 'with array prompt' do
      it 'uses array directly as messages' do
        prompt = [
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there!' },
          { role: 'user', content: 'How are you?' }
        ]
        
        result = llm_interface.execute_llm_call(prompt: prompt)
        
        expect(result).to eq('Test response')
        expect(llm_interface).to have_received(:chat_completion).with(
          params: hash_including(
            model: model,
            temperature: 0.7,
            max_tokens: 1000
          )
        )
      end
    end

    context 'with hash prompt' do
      it 'converts hash to array' do
        prompt = { role: 'user', content: 'Hello' }
        
        result = llm_interface.execute_llm_call(prompt: prompt)
        
        expect(result).to eq('Test response')
        expect(llm_interface).to have_received(:chat_completion).with(
          params: hash_including(
            model: model,
            temperature: 0.7,
            max_tokens: 1000
          )
        )
      end
    end

    context 'with custom model parameters' do
      it 'merges custom parameters with defaults' do
        prompt = 'Hello'
        model_params = { temperature: 0.5, max_tokens: 500 }
        
        result = llm_interface.execute_llm_call(prompt: prompt, model_params: model_params)
        
        expect(result).to eq('Test response')
        expect(llm_interface).to have_received(:chat_completion).with(
          params: hash_including(
            model: model,
            temperature: 0.5,
            max_tokens: 500
          )
        )
      end
    end

    context 'with different response formats' do
      it 'handles symbol-based response format' do
        allow(llm_interface).to receive(:chat_completion).and_return('Symbol response')
        
        result = llm_interface.execute_llm_call(prompt: 'Hello')
        
        expect(result).to eq('Symbol response')
      end

      it 'handles direct content response' do
        allow(llm_interface).to receive(:chat_completion).and_return('Direct content')
        
        result = llm_interface.execute_llm_call(prompt: 'Hello')
        
        expect(result).to eq('Direct content')
      end

      it 'handles string response' do
        allow(llm_interface).to receive(:chat_completion).and_return('Simple string response')
        
        result = llm_interface.execute_llm_call(prompt: 'Hello')
        
        expect(result).to eq('Simple string response')
      end
    end

    context 'error handling' do
      it 'raises TaskExecutionError when LLM call fails' do
        allow(llm_interface).to receive(:chat_completion).and_raise(StandardError.new('API Error'))
        
        expect {
          llm_interface.execute_llm_call(prompt: 'Hello')
        }.to raise_error(Rdawn::Errors::TaskExecutionError, 'LLM call failed: API Error')
      end

      it 'raises TaskExecutionError for invalid prompt format' do
        expect {
          llm_interface.execute_llm_call(prompt: 123)
        }.to raise_error(Rdawn::Errors::TaskExecutionError, 'LLM call failed: Invalid prompt format: Integer')
      end

      it 'raises ConfigurationError for unsupported provider' do
        expect {
          described_class.new(provider: :unsupported, api_key: 'test', model: 'test')
        }.to raise_error(Rdawn::Errors::ConfigurationError, 'Unsupported provider: unsupported')
      end
    end
  end
end 