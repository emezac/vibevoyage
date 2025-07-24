# frozen_string_literal: true

module Rdawn
  module Rails
    # Job for executing rdawn workflows in the background
    class WorkflowJob < ApplicationJob
      # Execute a workflow with the given configuration
      def perform(workflow_data:, llm_config:, initial_input: {}, user_context: {})
        safe_workflow_execution do
          # Build the workflow from the provided data
          workflow = build_workflow(workflow_data)
          
          # Create LLM interface with the provided configuration
          llm_interface = Rdawn::LLMInterface.new(**llm_config)
          
          # Create and configure the agent
          agent = Rdawn::Agent.new(
            workflow: workflow,
            llm_interface: llm_interface
          )
          
          # Build the initial context with Rails-specific data
          context = build_workflow_context(user_context).merge(initial_input)
          
          # Execute the workflow
          result = agent.run(initial_input: context)
          
          # Log successful completion
          #Rails.logger.info "Rdawn workflow completed successfully: #{workflow.workflow_id}"
          ::Rails.logger.info "Rdawn workflow completed successfully: #{workflow.workflow_id}"
          
          result
        end
      end
      
      # Class method to easily enqueue workflows
      def self.run_workflow_later(workflow_data:, llm_config:, initial_input: {}, user_context: {})
        perform_later(
          workflow_data: workflow_data,
          llm_config: llm_config,
          initial_input: initial_input,
          user_context: user_context
        )
      end
      
      # Class method to run workflows immediately (for testing/debugging)
      def self.run_workflow_now(workflow_data:, llm_config:, initial_input: {}, user_context: {})
        perform_now(
          workflow_data: workflow_data,
          llm_config: llm_config,
          initial_input: initial_input,
          user_context: user_context
        )
      end
      
      private
      
      # Build a workflow from serialized data
      def build_workflow(workflow_data)
        # Extract workflow metadata
        workflow_id = workflow_data[:workflow_id] || workflow_data['workflow_id']
        workflow_name = workflow_data[:name] || workflow_data['name']
        tasks_data = workflow_data[:tasks] || workflow_data['tasks'] || {}
        
        # Create the workflow
        workflow = Rdawn::Workflow.new(
          workflow_id: workflow_id,
          name: workflow_name
        )
        
        # Build and add tasks
        tasks_data.each do |task_id, task_data|
          task = build_task(task_id, task_data)
          workflow.add_task(task)
        end
        
        workflow
      end
      
      # Build a task from serialized data
      def build_task(task_id, task_data)
        # Extract task metadata
        task_name = task_data[:name] || task_data['name']
        task_type = task_data[:type] || task_data['type']
        input_data = task_data[:input_data] || task_data['input_data'] || {}
        
        # Create the appropriate task type
        case task_type
        when 'direct_handler'
          build_direct_handler_task(task_id, task_name, task_data, input_data)
        when 'llm'
          build_llm_task(task_id, task_name, task_data, input_data)
        when 'tool'
          build_tool_task(task_id, task_name, task_data, input_data)
        else
          # Default to basic task
          build_basic_task(task_id, task_name, task_data, input_data)
        end
      end
      
      # Build a direct handler task
      def build_direct_handler_task(task_id, task_name, task_data, input_data)
        handler_code = task_data[:handler] || task_data['handler']
        
        # For security, we only allow predefined handlers in Rails context
        # The handler should be a string reference to a Rails class/method
        if handler_code.is_a?(String)
          handler = resolve_handler_reference(handler_code)
        else
          raise Rdawn::Errors::ConfigurationError, "Direct handler must be a string reference in Rails context"
        end
        
        task = Rdawn::Tasks::DirectHandlerTask.new(
          task_id: task_id,
          name: task_name,
          input_data: input_data,
          handler: handler
        )
        
        configure_task_flow(task, task_data)
        task
      end
      
      # Build an LLM task
      def build_llm_task(task_id, task_name, task_data, input_data)
        task = Rdawn::Task.new(
          task_id: task_id,
          name: task_name,
          input_data: input_data,
          is_llm_task: true
        )
        
        configure_task_flow(task, task_data)
        task
      end
      
      # Build a tool task
      def build_tool_task(task_id, task_name, task_data, input_data)
        tool_name = task_data[:tool_name] || task_data['tool_name']
        
        task = Rdawn::Task.new(
          task_id: task_id,
          name: task_name,
          input_data: input_data,
          tool_name: tool_name
        )
        
        configure_task_flow(task, task_data)
        task
      end
      
      # Build a basic task
      def build_basic_task(task_id, task_name, task_data, input_data)
        task = Rdawn::Task.new(
          task_id: task_id,
          name: task_name,
          input_data: input_data
        )
        
        configure_task_flow(task, task_data)
        task
      end
      
      # Configure task flow control
      def configure_task_flow(task, task_data)
        task.next_task_id_on_success = task_data[:next_task_id_on_success] || task_data['next_task_id_on_success']
        task.next_task_id_on_failure = task_data[:next_task_id_on_failure] || task_data['next_task_id_on_failure']
        task.condition = task_data[:condition] || task_data['condition']
        task.max_retries = task_data[:max_retries] || task_data['max_retries'] || 0
      end
      
      # Resolve handler reference to actual handler
      def resolve_handler_reference(handler_ref)
        # Split the reference into class and method
        parts = handler_ref.split('#')
        
        if parts.length == 2
          class_name, method_name = parts
          klass = class_name.constantize
          
          # Return a proc that calls the method on the class
          proc do |input_data, workflow_variables|
            instance = klass.new
            instance.public_send(method_name, input_data, workflow_variables)
          end
        else
          # Assume it's a class with a call method
          klass = handler_ref.constantize
          
          proc do |input_data, workflow_variables|
            klass.call(input_data, workflow_variables)
          end
        end
      rescue NameError => e
        raise Rdawn::Errors::ConfigurationError, "Invalid handler reference: #{handler_ref} (#{e.message})"
      end
    end
  end
end 