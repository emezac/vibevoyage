# frozen_string_literal: true

require 'rufus-scheduler'
require 'json'
require 'concurrent'
require 'rdawn/errors'

module Rdawn
  module Tools
    # A comprehensive cron tool for scheduling tasks and workflows using rufus-scheduler
    class CronTool
      attr_reader :scheduler, :jobs, :statistics, :callbacks

      def initialize(options = {})
        @scheduler = Rufus::Scheduler.new
        @jobs = {}
        @statistics = {
          total_jobs: 0,
          active_jobs: 0,
          completed_jobs: 0,
          failed_jobs: 0,
          last_execution: nil
        }
        @callbacks = {}
        @mutex = Mutex.new
        @logger = options[:logger] || (defined?(Rails) ? Rails.logger : Logger.new(STDOUT))
        
        # Start the scheduler
        start_scheduler
      end

      # Schedule a task with cron expression
      def schedule_task(name:, cron_expression:, task_proc: nil, workflow_id: nil, tool_name: nil, input_data: {}, options: {})
        # Schedule a task using cron expression
        #
        # Args:
        #   name (String): Unique name for the scheduled task
        #   cron_expression (String): Cron expression (e.g., "0 9 * * *" for daily at 9 AM)
        #   task_proc (Proc): Optional proc to execute
        #   workflow_id (String): Optional workflow ID to execute
        #   tool_name (String): Optional tool name to execute
        #   input_data (Hash): Data to pass to the task/workflow/tool
        #   options (Hash): Additional options
        #
        # Returns:
        #   Hash: Job information
        
        raise Rdawn::Errors::ConfigurationError, 'Task name is required' if name.nil? || name.empty?
        raise Rdawn::Errors::ConfigurationError, 'Cron expression is required' if cron_expression.nil? || cron_expression.empty?
        
        # Validate cron expression
        unless valid_cron_expression?(cron_expression)
          raise Rdawn::Errors::ConfigurationError, "Invalid cron expression: #{cron_expression}"
        end
        
        # Check if job already exists
        if @jobs.key?(name)
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' already exists"
        end
        
        # Create execution handler
        execution_handler = create_execution_handler(
          name: name,
          task_proc: task_proc,
          workflow_id: workflow_id,
          tool_name: tool_name,
          input_data: input_data,
          options: options
        )
        
        # Schedule the job
        job_id = @scheduler.cron(cron_expression, &execution_handler)
        job = @scheduler.job(job_id)
        
        # Store job information
        @mutex.synchronize do
          @jobs[name] = {
            id: job_id,
            name: name,
            cron_expression: cron_expression,
            task_proc: task_proc,
            workflow_id: workflow_id,
            tool_name: tool_name,
            input_data: input_data,
            options: options,
            job: job,
            created_at: Time.now,
            executions: 0,
            last_execution: nil,
            last_result: nil,
            status: 'active'
          }
          @statistics[:total_jobs] += 1
          @statistics[:active_jobs] += 1
        end
        
        {
          name: name,
          job_id: job_id,
          cron_expression: cron_expression,
          status: 'scheduled',
          created_at: Time.now,
          next_time: job.next_time
        }
      end

      # Schedule a one-time task
      def schedule_once(name:, at_time:, task_proc: nil, workflow_id: nil, tool_name: nil, input_data: {}, options: {})
        # Schedule a one-time task
        #
        # Args:
        #   name (String): Unique name for the scheduled task
        #   at_time (Time, String): When to execute (Time object or string like "2025-01-01 10:00:00")
        #   task_proc (Proc): Optional proc to execute
        #   workflow_id (String): Optional workflow ID to execute
        #   tool_name (String): Optional tool name to execute
        #   input_data (Hash): Data to pass to the task/workflow/tool
        #   options (Hash): Additional options
        #
        # Returns:
        #   Hash: Job information
        
        raise Rdawn::Errors::ConfigurationError, 'Task name is required' if name.nil? || name.empty?
        raise Rdawn::Errors::ConfigurationError, 'Execution time is required' if at_time.nil?
        
        # Parse time if string
        parsed_time = at_time.is_a?(String) ? Time.parse(at_time) : at_time
        
        # Check if time is in the future
        if parsed_time <= Time.now
          raise Rdawn::Errors::ConfigurationError, 'Execution time must be in the future'
        end
        
        # Check if job already exists
        if @jobs.key?(name)
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' already exists"
        end
        
        # Create execution handler
        execution_handler = create_execution_handler(
          name: name,
          task_proc: task_proc,
          workflow_id: workflow_id,
          tool_name: tool_name,
          input_data: input_data,
          options: options
        )
        
        # Schedule the job
        job_id = @scheduler.at(parsed_time, &execution_handler)
        job = @scheduler.job(job_id)
        
        # Store job information
        @mutex.synchronize do
          @jobs[name] = {
            id: job_id,
            name: name,
            at_time: parsed_time,
            task_proc: task_proc,
            workflow_id: workflow_id,
            tool_name: tool_name,
            input_data: input_data,
            options: options,
            job: job,
            created_at: Time.now,
            executions: 0,
            last_execution: nil,
            last_result: nil,
            status: 'scheduled'
          }
          @statistics[:total_jobs] += 1
          @statistics[:active_jobs] += 1
        end
        
        {
          name: name,
          job_id: job_id,
          at_time: parsed_time,
          status: 'scheduled',
          created_at: Time.now
        }
      end

      # Schedule a recurring task with interval
      def schedule_recurring(name:, interval:, task_proc: nil, workflow_id: nil, tool_name: nil, input_data: {}, options: {})
        # Schedule a recurring task with interval
        #
        # Args:
        #   name (String): Unique name for the scheduled task
        #   interval (String): Interval expression (e.g., "30s", "5m", "1h", "1d")
        #   task_proc (Proc): Optional proc to execute
        #   workflow_id (String): Optional workflow ID to execute
        #   tool_name (String): Optional tool name to execute
        #   input_data (Hash): Data to pass to the task/workflow/tool
        #   options (Hash): Additional options
        #
        # Returns:
        #   Hash: Job information
        
        raise Rdawn::Errors::ConfigurationError, 'Task name is required' if name.nil? || name.empty?
        raise Rdawn::Errors::ConfigurationError, 'Interval is required' if interval.nil? || interval.empty?
        
        # Check if job already exists
        if @jobs.key?(name)
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' already exists"
        end
        
        # Create execution handler
        execution_handler = create_execution_handler(
          name: name,
          task_proc: task_proc,
          workflow_id: workflow_id,
          tool_name: tool_name,
          input_data: input_data,
          options: options
        )
        
        # Schedule the job
        job_id = @scheduler.every(interval, &execution_handler)
        job = @scheduler.job(job_id)
        
        # Store job information
        @mutex.synchronize do
          @jobs[name] = {
            id: job_id,
            name: name,
            interval: interval,
            task_proc: task_proc,
            workflow_id: workflow_id,
            tool_name: tool_name,
            input_data: input_data,
            options: options,
            job: job,
            created_at: Time.now,
            executions: 0,
            last_execution: nil,
            last_result: nil,
            status: 'active'
          }
          @statistics[:total_jobs] += 1
          @statistics[:active_jobs] += 1
        end
        
        {
          name: name,
          job_id: job_id,
          interval: interval,
          status: 'scheduled',
          created_at: Time.now,
          next_time: job.next_time
        }
      end

      # Unschedule a job
      def unschedule_job(name:)
        # Unschedule a job by name
        #
        # Args:
        #   name (String): Name of the job to unschedule
        #
        # Returns:
        #   Hash: Unschedule result
        
        raise Rdawn::Errors::ConfigurationError, 'Job name is required' if name.nil? || name.empty?
        
        job_info = @jobs[name]
        unless job_info
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' not found"
        end
        
        # Unschedule the job
        job_info[:job].unschedule
        
        # Update job information
        @mutex.synchronize do
          @jobs[name][:status] = 'unscheduled'
          @jobs[name][:unscheduled_at] = Time.now
          @statistics[:active_jobs] -= 1
        end
        
        {
          name: name,
          status: 'unscheduled',
          unscheduled_at: Time.now
        }
      end

      # List all jobs
      def list_jobs
        # List all scheduled jobs
        #
        # Returns:
        #   Hash: Jobs information
        
        @mutex.synchronize do
          {
            total_jobs: @jobs.size,
            active_jobs: @jobs.count { |_, job| job[:status] == 'active' },
            jobs: @jobs.map do |name, job_info|
              {
                name: name,
                status: job_info[:status],
                type: determine_job_type(job_info),
                schedule: determine_schedule_info(job_info),
                executions: job_info[:executions],
                last_execution: job_info[:last_execution],
                created_at: job_info[:created_at],
                next_time: job_info[:job].next_time
              }
            end
          }
        end
      end

      # Get job information
      def get_job(name:)
        # Get information about a specific job
        #
        # Args:
        #   name (String): Name of the job
        #
        # Returns:
        #   Hash: Job information
        
        raise Rdawn::Errors::ConfigurationError, 'Job name is required' if name.nil? || name.empty?
        
        job_info = @jobs[name]
        unless job_info
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' not found"
        end
        
        {
          name: name,
          job_id: job_info[:id],
          status: job_info[:status],
          type: determine_job_type(job_info),
          schedule: determine_schedule_info(job_info),
          executions: job_info[:executions],
          last_execution: job_info[:last_execution],
          last_result: job_info[:last_result],
          created_at: job_info[:created_at],
          next_time: job_info[:job].next_time
        }
      end

      # Execute a job immediately
      def execute_job_now(name:)
        # Execute a job immediately (outside of its schedule)
        #
        # Args:
        #   name (String): Name of the job to execute
        #
        # Returns:
        #   Hash: Execution result
        
        raise Rdawn::Errors::ConfigurationError, 'Job name is required' if name.nil? || name.empty?
        
        job_info = @jobs[name]
        unless job_info
          raise Rdawn::Errors::ConfigurationError, "Job with name '#{name}' not found"
        end
        
        # Execute the job
        result = execute_job_task(job_info)
        
        {
          name: name,
          executed_at: Time.now,
          result: result
        }
      end

      # Get scheduler statistics
      def get_statistics
        # Get scheduler statistics
        #
        # Returns:
        #   Hash: Statistics information
        
        @mutex.synchronize do
          {
            scheduler_status: @scheduler.up? ? 'running' : 'stopped',
            total_jobs: @statistics[:total_jobs],
            active_jobs: @statistics[:active_jobs],
            completed_jobs: @statistics[:completed_jobs],
            failed_jobs: @statistics[:failed_jobs],
            last_execution: @statistics[:last_execution],
            uptime: @scheduler.uptime,
            threads: @scheduler.threads.size
          }
        end
      end

      # Stop the scheduler
      def stop_scheduler
        # Stop the scheduler
        #
        # Returns:
        #   Hash: Stop result
        
        @scheduler.stop
        
        {
          status: 'stopped',
          stopped_at: Time.now
        }
      end

      # Restart the scheduler
      def restart_scheduler
        # Restart the scheduler
        #
        # Returns:
        #   Hash: Restart result
        
        @scheduler.stop
        @scheduler = Rufus::Scheduler.new
        start_scheduler
        
        {
          status: 'restarted',
          restarted_at: Time.now
        }
      end

      # Set callback for job events
      def set_callback(event:, callback_proc:)
        # Set a callback for job events
        #
        # Args:
        #   event (String): Event type ('before_execution', 'after_execution', 'on_error')
        #   callback_proc (Proc): Callback procedure
        #
        # Returns:
        #   Hash: Callback registration result
        
        valid_events = %w[before_execution after_execution on_error]
        unless valid_events.include?(event)
          raise Rdawn::Errors::ConfigurationError, "Invalid event: #{event}. Valid events: #{valid_events.join(', ')}"
        end
        
        @callbacks[event] = callback_proc
        
        {
          event: event,
          callback_set: true,
          set_at: Time.now
        }
      end

      # Execute method for ToolRegistry compatibility
      def execute(input_data = {})
        # Execute method for ToolRegistry compatibility
        #
        # Args:
        #   input_data (Hash): Input data with action and parameters
        #
        # Returns:
        #   Hash: Execution result
        
        action = input_data['action'] || input_data[:action]
        
        case action
        when 'schedule_task'
          schedule_task(
            name: input_data['name'] || input_data[:name],
            cron_expression: input_data['cron_expression'] || input_data[:cron_expression],
            task_proc: input_data['task_proc'] || input_data[:task_proc],
            workflow_id: input_data['workflow_id'] || input_data[:workflow_id],
            tool_name: input_data['tool_name'] || input_data[:tool_name],
            input_data: input_data['input_data'] || input_data[:input_data] || {},
            options: input_data['options'] || input_data[:options] || {}
          )
        when 'schedule_once'
          schedule_once(
            name: input_data['name'] || input_data[:name],
            at_time: input_data['at_time'] || input_data[:at_time],
            task_proc: input_data['task_proc'] || input_data[:task_proc],
            workflow_id: input_data['workflow_id'] || input_data[:workflow_id],
            tool_name: input_data['tool_name'] || input_data[:tool_name],
            input_data: input_data['input_data'] || input_data[:input_data] || {},
            options: input_data['options'] || input_data[:options] || {}
          )
        when 'schedule_recurring'
          schedule_recurring(
            name: input_data['name'] || input_data[:name],
            interval: input_data['interval'] || input_data[:interval],
            task_proc: input_data['task_proc'] || input_data[:task_proc],
            workflow_id: input_data['workflow_id'] || input_data[:workflow_id],
            tool_name: input_data['tool_name'] || input_data[:tool_name],
            input_data: input_data['input_data'] || input_data[:input_data] || {},
            options: input_data['options'] || input_data[:options] || {}
          )
        when 'unschedule_job'
          unschedule_job(name: input_data['name'] || input_data[:name])
        when 'list_jobs'
          list_jobs
        when 'get_job'
          get_job(name: input_data['name'] || input_data[:name])
        when 'execute_job_now'
          execute_job_now(name: input_data['name'] || input_data[:name])
        when 'get_statistics'
          get_statistics
        when 'stop_scheduler'
          stop_scheduler
        when 'restart_scheduler'
          restart_scheduler
        else
          raise Rdawn::Errors::ConfigurationError, "Unknown action: #{action}"
        end
      end

      private

      def start_scheduler
        # Rufus::Scheduler starts automatically, no need to call start
        # The scheduler is already running after initialization
      end

      def valid_cron_expression?(expression)
        # Basic cron expression validation
        parts = expression.split
        return false unless parts.length == 5
        
        # More thorough validation could be added here
        true
      end

      def create_execution_handler(name:, task_proc:, workflow_id:, tool_name:, input_data:, options:)
        # Create an execution handler for the scheduled job
        proc do |job|
          begin
            # Call before_execution callback
            @callbacks['before_execution']&.call(name, job)
            
            # Execute the job
            result = execute_job_task({
              name: name,
              task_proc: task_proc,
              workflow_id: workflow_id,
              tool_name: tool_name,
              input_data: input_data,
              options: options
            })
            
            # Update job statistics
            @mutex.synchronize do
              @jobs[name][:executions] += 1
              @jobs[name][:last_execution] = Time.now
              @jobs[name][:last_result] = result
              @statistics[:last_execution] = Time.now
              @statistics[:completed_jobs] += 1
            end
            
            # Call after_execution callback
            @callbacks['after_execution']&.call(name, job, result)
            
            @logger.info "Job '#{name}' executed successfully"
            
          rescue => e
            # Update error statistics
            @mutex.synchronize do
              @jobs[name][:last_execution] = Time.now
              @jobs[name][:last_result] = { error: e.message }
              @statistics[:failed_jobs] += 1
            end
            
            # Call error callback
            @callbacks['on_error']&.call(name, job, e)
            
            @logger.error "Job '#{name}' failed: #{e.message}"
            
            raise e if options[:raise_on_error]
          end
        end
      end

      def execute_job_task(job_info)
        # Execute the actual job task
        name = job_info[:name]
        task_proc = job_info[:task_proc]
        workflow_id = job_info[:workflow_id]
        tool_name = job_info[:tool_name]
        input_data = job_info[:input_data]
        options = job_info[:options]
        
        if task_proc
          # Execute custom proc
          task_proc.call(input_data)
        elsif workflow_id
          # Execute workflow
          execute_workflow(workflow_id, input_data)
        elsif tool_name
          # Execute tool
          execute_tool(tool_name, input_data)
        else
          raise Rdawn::Errors::ConfigurationError, "No execution target specified for job '#{name}'"
        end
      end

      def execute_workflow(workflow_id, input_data)
        # Execute a workflow (placeholder - should integrate with WorkflowEngine)
        if defined?(Rdawn::WorkflowEngine)
          # This would be the actual workflow execution
          { 
            type: 'workflow',
            workflow_id: workflow_id,
            input_data: input_data,
            executed_at: Time.now,
            result: 'Workflow execution not implemented in this version'
          }
        else
          raise Rdawn::Errors::ConfigurationError, "Workflow execution not available"
        end
      end

      def execute_tool(tool_name, input_data)
        # Execute a tool using ToolRegistry
        if defined?(Rdawn::ToolRegistry)
          if Rdawn::ToolRegistry.tool_exists?(tool_name)
            result = Rdawn::ToolRegistry.execute(tool_name, input_data)
            {
              type: 'tool',
              tool_name: tool_name,
              input_data: input_data,
              executed_at: Time.now,
              result: result
            }
          else
            raise Rdawn::Errors::ToolNotFoundError, "Tool '#{tool_name}' not found"
          end
        else
          raise Rdawn::Errors::ConfigurationError, "ToolRegistry not available"
        end
      end

      def determine_job_type(job_info)
        if job_info[:cron_expression]
          'cron'
        elsif job_info[:interval]
          'recurring'
        elsif job_info[:at_time]
          'once'
        else
          'unknown'
        end
      end

      def determine_schedule_info(job_info)
        if job_info[:cron_expression]
          { type: 'cron', expression: job_info[:cron_expression] }
        elsif job_info[:interval]
          { type: 'recurring', interval: job_info[:interval] }
        elsif job_info[:at_time]
          { type: 'once', at_time: job_info[:at_time] }
        else
          { type: 'unknown' }
        end
      end
    end
  end
end 