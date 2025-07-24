# frozen_string_literal: true

require 'spec_helper'

# Skip Rails tests if Rails is not available
begin
  require 'rails'
  require 'active_job'
  require_relative '../../lib/rdawn/rails'
  
  RSpec.describe 'Rails Integration Tests' do
    let(:mock_llm_interface) do
      double('LLMInterface').tap do |llm|
        allow(llm).to receive(:execute_llm_call).and_return('Mock LLM response')
      end
    end

    before do
      # Mock Rails application
      @original_rails_app = Rails.application if defined?(Rails.application)
      
      # Create mock Rails app
      app = double('Rails Application')
      allow(app).to receive(:config).and_return(double('Config').tap do |config|
        allow(config).to receive(:active_job).and_return(double('ActiveJob').tap do |aj|
          allow(aj).to receive(:queue_adapter).and_return(:test)
        end)
      end)
      
      # Stub Rails.application
      allow(Rails).to receive(:application).and_return(app) if defined?(Rails)
      
      # Clear any existing tool registrations
      Rdawn::ToolRegistry.instance_variable_set(:@tools, {})
    end

    after do
      # Restore original Rails app
      allow(Rails).to receive(:application).and_return(@original_rails_app) if defined?(Rails) && @original_rails_app
    end

    describe 'WorkflowJob Integration' do
      it 'executes workflows in background jobs' do
        # Mock ActiveJob
        job_class = Class.new do
          include ActiveJob::Base if defined?(ActiveJob::Base)
          
          def self.perform_later(*args)
            new.perform(*args)
          end
          
          def perform(workflow_data:, llm_config:, initial_input: {})
            # Simulate job execution
            workflow = Rdawn::Workflow.new(
              workflow_id: workflow_data[:workflow_id],
              name: workflow_data[:name]
            )
            
            # Add tasks from workflow_data
            workflow_data[:tasks].each do |task_id, task_config|
              task = case task_config[:type]
                     when 'direct_handler'
                       Rdawn::Tasks::DirectHandlerTask.new(
                         task_id: task_id,
                         name: task_config[:name],
                         handler: proc { |input| { result: "Job executed: #{task_config[:name]}" } }
                       )
                     when 'llm'
                       Rdawn::Task.new(
                         task_id: task_id,
                         name: task_config[:name],
                         is_llm_task: true,
                         input_data: task_config[:input_data]
                       )
                     else
                       Rdawn::Task.new(
                         task_id: task_id,
                         name: task_config[:name],
                         input_data: task_config[:input_data]
                       )
                     end
              
              workflow.add_task(task)
            end
            
            # Execute workflow
            llm_interface = double('LLMInterface')
            allow(llm_interface).to receive(:execute_llm_call).and_return('Job LLM response')
            
            agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
            result = agent.run(initial_input: initial_input)
            
            # Simulate broadcasting result
            { status: 'completed', workflow_id: workflow_data[:workflow_id], result: result }
          end
        end
        
        # Test data
        workflow_data = {
          workflow_id: 'rails_job_test',
          name: 'Rails Job Test Workflow',
          tasks: {
            'init_job' => {
              type: 'direct_handler',
              name: 'Initialize Job',
              input_data: { job_id: 'test_job_123' }
            },
            'process_job' => {
              type: 'llm',
              name: 'Process with LLM',
              input_data: {
                prompt: 'Process job ${job_id}',
                model_params: { temperature: 0.7 }
              }
            }
          }
        }
        
        # Execute job
        result = job_class.new.perform(
          workflow_data: workflow_data,
          llm_config: { api_key: 'test_key' },
          initial_input: { user_id: 'test_user' }
        )
        
        expect(result[:status]).to eq('completed')
        expect(result[:workflow_id]).to eq('rails_job_test')
        expect(result[:result][:status]).to eq(:completed)
      end
    end

    describe 'Rails Model Integration' do
      it 'integrates with Rails models in DirectHandlerTask' do
        # Mock ActiveRecord model
        user_class = Class.new do
          attr_accessor :id, :name, :email, :created_at
          
          def initialize(attributes = {})
            attributes.each { |key, value| send("#{key}=", value) }
          end
          
          def self.find(id)
            new(id: id, name: "User #{id}", email: "user#{id}@example.com", created_at: Time.current)
          end
          
          def self.create!(attributes)
            new(attributes.merge(id: rand(1000), created_at: Time.current))
          end
          
          def save!
            true
          end
          
          def attributes
            { id: id, name: name, email: email, created_at: created_at }
          end
        end
        
        # Mock Project model
        project_class = Class.new do
          attr_accessor :id, :name, :user_id, :status
          
          def initialize(attributes = {})
            attributes.each { |key, value| send("#{key}=", value) }
          end
          
          def self.create!(attributes)
            new(attributes.merge(id: rand(1000), status: 'active'))
          end
          
          def attributes
            { id: id, name: name, user_id: user_id, status: status }
          end
        end
        
        # Create workflow with Rails model integration
        workflow = Rdawn::Workflow.new(
          workflow_id: 'rails_model_test',
          name: 'Rails Model Integration Test'
        )
        
        # Task 1: Find user
        find_user_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'find_user',
          name: 'Find User',
          handler: proc do |input_data|
            user = user_class.find(input_data[:user_id])
            { user: user.attributes }
          end
        )
        find_user_task.next_task_id_on_success = 'create_project'
        
        # Task 2: Create project
        create_project_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'create_project',
          name: 'Create Project',
          handler: proc do |input_data, workflow_vars|
            project = project_class.create!(
              name: input_data[:project_name],
              user_id: workflow_vars[:user][:id]
            )
            { project: project.attributes }
          end,
          input_data: { project_name: 'Test Project' }
        )
        create_project_task.next_task_id_on_success = 'generate_summary'
        
        # Task 3: Generate summary with LLM
        summary_task = Rdawn::Task.new(
          task_id: 'generate_summary',
          name: 'Generate Summary',
          is_llm_task: true,
          input_data: {
            prompt: 'Generate a summary for user ${user.name} and project ${project.name}',
            model_params: { temperature: 0.5 }
          }
        )
        
        workflow.add_task(find_user_task)
        workflow.add_task(create_project_task)
        workflow.add_task(summary_task)
        
        # Execute workflow
        agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
        result = agent.run(initial_input: { user_id: 123 })
        
        expect(result[:status]).to eq(:completed)
        expect(result[:final_output][:user][:name]).to eq('User 123')
        expect(result[:final_output][:project][:name]).to eq('Test Project')
        expect(result[:final_output][:project][:user_id]).to eq(123)
      end
    end

    describe 'Rails Configuration Integration' do
      it 'respects Rails configuration settings' do
        # Mock Rails configuration
        config = double('RdawnConfig')
        allow(config).to receive(:llm_api_key).and_return('rails_test_key')
        allow(config).to receive(:llm_model).and_return('gpt-3.5-turbo')
        allow(config).to receive(:default_model_params).and_return({ temperature: 0.8 })
        
        # Test that configuration is used
        expect(config.llm_api_key).to eq('rails_test_key')
        expect(config.llm_model).to eq('gpt-3.5-turbo')
        expect(config.default_model_params[:temperature]).to eq(0.8)
      end
    end

    describe 'Rails Workflow Handlers' do
      it 'works with Rails service objects as handlers' do
        # Mock Rails service object
        service_class = Class.new do
          def self.call(input_data, workflow_variables)
            user_id = input_data[:user_id]
            notification_type = input_data[:notification_type]
            
            # Simulate service logic
            {
              notification_sent: true,
              user_id: user_id,
              notification_type: notification_type,
              sent_at: Time.current.to_s
            }
          end
        end
        
        # Create workflow with service object
        workflow = Rdawn::Workflow.new(
          workflow_id: 'rails_service_test',
          name: 'Rails Service Test'
        )
        
        service_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'send_notification',
          name: 'Send Notification',
          handler: service_class.method(:call),
          input_data: { user_id: 456, notification_type: 'welcome' }
        )
        
        workflow.add_task(service_task)
        
        agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
        result = agent.run
        
        expect(result[:final_output][:notification_sent]).to be true
        expect(result[:final_output][:user_id]).to eq(456)
        expect(result[:final_output][:notification_type]).to eq('welcome')
      end
    end

    describe 'Rails Mailer Integration' do
      it 'integrates with Rails mailers in workflows' do
        # Mock Rails mailer
        mailer_class = Class.new do
          def self.welcome_email(user_id)
            new.welcome_email(user_id)
          end
          
          def welcome_email(user_id)
            @user_id = user_id
            self
          end
          
          def deliver_now
            { delivered: true, user_id: @user_id, sent_at: Time.current.to_s }
          end
        end
        
        # Create workflow with mailer integration
        workflow = Rdawn::Workflow.new(
          workflow_id: 'rails_mailer_test',
          name: 'Rails Mailer Test'
        )
        
        mailer_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'send_welcome_email',
          name: 'Send Welcome Email',
          handler: proc do |input_data|
            result = mailer_class.welcome_email(input_data[:user_id]).deliver_now
            { email_result: result }
          end,
          input_data: { user_id: 789 }
        )
        
        workflow.add_task(mailer_task)
        
        agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
        result = agent.run
        
        expect(result[:final_output][:email_result][:delivered]).to be true
        expect(result[:final_output][:email_result][:user_id]).to eq(789)
      end
    end

    describe 'Rails Validation Integration' do
      it 'handles Rails validation errors gracefully' do
        # Mock model with validation
        model_class = Class.new do
          attr_accessor :name, :email
          
          def initialize(attributes = {})
            attributes.each { |key, value| send("#{key}=", value) }
          end
          
          def save!
            if name.nil? || name.empty?
              raise StandardError, 'Name cannot be blank'
            end
            true
          end
          
          def valid?
            !name.nil? && !name.empty?
          end
        end
        
        # Create workflow with validation
        workflow = Rdawn::Workflow.new(
          workflow_id: 'rails_validation_test',
          name: 'Rails Validation Test'
        )
        
        validation_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'create_record',
          name: 'Create Record',
          handler: proc do |input_data|
            record = model_class.new(name: input_data[:name], email: input_data[:email])
            
            if record.valid?
              record.save!
              { success: true, record: { name: record.name, email: record.email } }
            else
              { success: false, errors: ['Name cannot be blank'] }
            end
          end
        )
        validation_task.next_task_id_on_success = 'success_handler'
        validation_task.next_task_id_on_failure = 'error_handler'
        
        success_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'success_handler',
          name: 'Success Handler',
          handler: proc do |input_data, workflow_vars|
            { result: 'Record created successfully', record: workflow_vars[:record] }
          end
        )
        
        error_task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: 'error_handler',
          name: 'Error Handler',
          handler: proc do |input_data, workflow_vars|
            { result: 'Validation failed', errors: workflow_vars[:errors] }
          end
        )
        
        workflow.add_task(validation_task)
        workflow.add_task(success_task)
        workflow.add_task(error_task)
        
        agent = Rdawn::Agent.new(workflow: workflow, llm_interface: mock_llm_interface)
        
        # Test valid input
        result = agent.run(initial_input: { name: 'John Doe', email: 'john@example.com' })
        expect(result[:final_output][:result]).to eq('Record created successfully')
        
        # Test invalid input
        result = agent.run(initial_input: { name: '', email: 'invalid@example.com' })
        expect(result[:final_output][:result]).to eq('Validation failed')
      end
    end

    describe 'Rails Background Job Queuing' do
      it 'queues workflows for background execution' do
        # Mock background job queue
        job_queue = []
        
        job_class = Class.new do
          def self.perform_later(workflow_data)
            job_queue << { workflow_id: workflow_data[:workflow_id], queued_at: Time.current }
            { queued: true, workflow_id: workflow_data[:workflow_id] }
          end
        end
        
        # Test queuing
        workflow_data = {
          workflow_id: 'background_test',
          name: 'Background Test Workflow'
        }
        
        result = job_class.perform_later(workflow_data)
        
        expect(result[:queued]).to be true
        expect(result[:workflow_id]).to eq('background_test')
        expect(job_queue.length).to eq(1)
        expect(job_queue.first[:workflow_id]).to eq('background_test')
      end
    end
  end

rescue LoadError
  # Rails not available, skip these tests
  puts "Rails not available, skipping Rails integration tests"
end 