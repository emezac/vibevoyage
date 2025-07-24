# frozen_string_literal: true

require 'spec_helper'

# Skip Rails integration tests if Rails is not available
begin
  require 'rails'
  require 'active_job'
rescue LoadError
  # Rails not available, skip this test file
  return
end

# Mock Rails classes for testing
module Rails
  def self.env
    'test'
  end
  
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  
  def self.application
    @application ||= MockApplication.new
  end
  
  class MockApplication
    def config
      @config ||= MockConfig.new
    end
  end
  
  class MockConfig
    def active_job
      @active_job ||= MockActiveJob.new
    end
    
    def rdawn
      nil
    end
  end
  
  class MockActiveJob
    def queue_adapter
      :test
    end
  end
end

# Mock Time for Rails
class Time
  def self.current
    now
  end
end

# Now load the Rails integration
require 'rdawn/rails'

RSpec.describe 'Rails Integration' do
  describe 'Rdawn::Rails::Configuration' do
    it 'has default configuration values' do
      config = Rdawn::Rails::Configuration.new
      
      expect(config.default_queue_adapter).to eq(:async)
      expect(config.default_queue_name).to eq(:rdawn)
      expect(config.enable_active_job_integration).to be true
    end
    
    it 'allows configuration' do
      Rdawn::Rails.configure do |config|
        config.default_queue_name = :custom_queue
        config.enable_active_job_integration = false
      end
      
      expect(Rdawn::Rails.configuration.default_queue_name).to eq(:custom_queue)
      expect(Rdawn::Rails.configuration.enable_active_job_integration).to be false
    end
  end
  
  describe 'Rdawn::Rails::ApplicationJob' do
    it 'creates a job class' do
      expect(Rdawn::Rails::ApplicationJob).to be < ActiveJob::Base
    end
    
    it 'has helper methods' do
      job = Rdawn::Rails::ApplicationJob.new
      
      context = job.send(:build_workflow_context, user_id: 123)
      
      expect(context).to include(
        rails_env: 'test',
        timestamp: be_a(Time),
        job_id: 'test-job-123',
        job_class: 'Rdawn::Rails::ApplicationJob'
      )
      expect(context[:user_id]).to eq(123)
    end
  end
  
  describe 'Rdawn::Rails::WorkflowJob' do
    let(:llm_interface) { double('LLMInterface') }
    let(:workflow) { double('Workflow') }
    let(:agent) { double('Agent') }
    
    let(:workflow_data) do
      {
        workflow_id: 'test_workflow',
        name: 'Test Workflow',
        tasks: {
          'task1' => {
            type: 'basic',
            name: 'Test Task',
            input_data: { message: 'Hello' }
          }
        }
      }
    end
    
    let(:llm_config) do
      {
        api_key: 'test_key',
        model: 'gpt-4o-mini'
      }
    end
    
    before do
      allow(Rdawn::LLMInterface).to receive(:new).and_return(llm_interface)
      allow(Rdawn::Workflow).to receive(:new).and_return(workflow)
      allow(Rdawn::Agent).to receive(:new).and_return(agent)
      allow(Rdawn::Task).to receive(:new).and_return(double('Task'))
      allow(workflow).to receive(:add_task)
      allow(workflow).to receive(:workflow_id).and_return('test_workflow')
      allow(agent).to receive(:run).and_return(workflow)
    end
    
    it 'can build a workflow from data' do
      job = Rdawn::Rails::WorkflowJob.new
      
      built_workflow = job.send(:build_workflow, workflow_data)
      
      expect(built_workflow).to eq(workflow)
    end
    
    it 'can execute a workflow' do
      job = Rdawn::Rails::WorkflowJob.new
      
      result = job.perform(
        workflow_data: workflow_data,
        llm_config: llm_config,
        initial_input: { user_id: 123 }
      )
      
      expect(result).to eq(workflow)
      expect(agent).to have_received(:run).with(
        initial_input: hash_including(user_id: 123)
      )
    end
    
    it 'has class methods for easy workflow execution' do
      expect(Rdawn::Rails::WorkflowJob).to respond_to(:run_workflow_later)
      expect(Rdawn::Rails::WorkflowJob).to respond_to(:run_workflow_now)
    end
  end
  
  describe 'Configuration Integration' do
    it 'has main rdawn configuration' do
      Rdawn.configure do |config|
        config.llm_api_key = 'test_key'
        config.llm_model = 'gpt-4'
      end
      
      expect(Rdawn.configuration.llm_api_key).to eq('test_key')
      expect(Rdawn.configuration.llm_model).to eq('gpt-4')
    end
    
    it 'maintains separate Rails configuration' do
      Rdawn::Rails.configure do |config|
        config.default_queue_name = :test_queue
      end
      
      expect(Rdawn::Rails.configuration.default_queue_name).to eq(:test_queue)
    end
  end
end 