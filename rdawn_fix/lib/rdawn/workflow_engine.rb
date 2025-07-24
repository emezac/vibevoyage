# frozen_string_literal: true

module Rdawn
  class WorkflowEngine
    def initialize(workflow:, llm_interface:)
      @workflow = workflow
      @llm_interface = llm_interface
    end

    def run(initial_input: {})
      @workflow.status = :running
      @workflow.variables.merge!(initial_input)

      current_task = find_initial_task
      
      while current_task
        execute_task(current_task)
        
        current_task = case current_task.status
                      when :completed
                        find_next_task_with_condition(current_task.next_task_id_on_success, current_task)
                      when :failed
                        find_next_task_with_condition(current_task.next_task_id_on_failure, current_task)
                      else
                        nil
                      end
      end

      @workflow.status = :completed
      @workflow
    end

    private

    def find_initial_task
      # Find the first task that has no predecessors
      # For now, we'll assume the first task added is the initial task
      # In a more sophisticated implementation, we might look for tasks
      # that aren't referenced in any next_task_id_on_success/failure
      @workflow.tasks.values.first
    end

    def find_next_task(task_id)
      return nil unless task_id
      @workflow.get_task(task_id)
    end

    def find_next_task_with_condition(task_id, current_task)
      next_task = find_next_task(task_id)
      return nil unless next_task
      
      # If the next task has a condition, evaluate it
      if next_task.condition
        condition_result = evaluate_condition(next_task.condition, current_task)
        return nil unless condition_result
      end
      
      next_task
    end

    def evaluate_condition(condition, current_task)
      case condition
      when String
        # Simple string conditions - resolve variables and evaluate
        resolved_condition = Rdawn::VariableResolver.resolve(condition, build_context(current_task))
        evaluate_condition_expression(resolved_condition)
      when Hash
        # Hash-based conditions with operators
        evaluate_hash_condition(condition, current_task)
      when Proc
        # Proc-based conditions
        condition.call(current_task, @workflow)
      else
        # Default to truthy evaluation
        !!condition
      end
    end

    def evaluate_condition_expression(expression)
      # Simple expression evaluation for basic comparisons
      # This is a simplified version - in production, you might want a more robust parser
      case expression
      when true, false
        expression
      when String
        # Basic string evaluation - check for common patterns
        return true if ['true', 'yes', '1'].include?(expression.downcase)
        return false if ['false', 'no', '0', ''].include?(expression.downcase)
        # If it's a non-empty string, consider it truthy
        !expression.empty?
      else
        !!expression
      end
    end

    def evaluate_hash_condition(condition, current_task)
      # Handle hash-based conditions like { "eq" => ["${status}", "completed"] }
      condition.each do |operator, operands|
        case operator
        when 'eq', 'equals'
          left, right = resolve_operands(operands, current_task)
          return left == right
        when 'ne', 'not_equals'
          left, right = resolve_operands(operands, current_task)
          return left != right
        when 'gt', 'greater_than'
          left, right = resolve_operands(operands, current_task)
          return left > right
        when 'lt', 'less_than'
          left, right = resolve_operands(operands, current_task)
          return left < right
        when 'contains'
          left, right = resolve_operands(operands, current_task)
          return left.to_s.include?(right.to_s)
        when 'exists'
          value = resolve_operands([operands].flatten.first, current_task)
          return !value.nil?
        else
          raise Rdawn::Errors::VariableResolutionError, "Unknown condition operator: #{operator}"
        end
      end
      false
    end

    def resolve_operands(operands, current_task)
      context = build_context(current_task)
      if operands.is_a?(Array)
        operands.map { |operand| Rdawn::VariableResolver.resolve(operand, context) }
      else
        Rdawn::VariableResolver.resolve(operands, context)
      end
    end

    def build_context(current_task = nil)
      context = @workflow.variables.dup
      
      # Add current task output if available
      if current_task && current_task.output_data
        context['current_task'] = current_task.output_data
      end
      
      # Add all task outputs organized by task_id
      @workflow.tasks.each do |task_id, task|
        next unless task.status == :completed && task.output_data
        context[task_id] = task.output_data
      end
      
      context
    end

    def execute_task(task)
      return unless task

      task.mark_running
      
      begin
        # Resolve variables in input_data before executing the task
        context = build_context(task)
        resolved_input_data = Rdawn::VariableResolver.resolve(task.input_data, context)
        
        # Temporarily update task input_data with resolved values for execution
        original_input_data = task.input_data
        task.input_data = resolved_input_data
        
        output = case
                 when task.is_llm_task
                   execute_llm_task(task)
                 when task.tool_name
                   execute_tool_task(task)
                 when task.is_a?(Rdawn::Tasks::DirectHandlerTask)
                   execute_direct_handler_task(task)
                 when task.respond_to?(:is_mcp_task) && task.is_mcp_task
                   execute_mcp_task(task)
                 else
                   # For now, just simulate execution by marking as completed
                   simulate_task_execution(task)
                 end
        
        task.mark_completed(output)
        
        # Restore original input_data (for debugging/inspection purposes)
        task.input_data = original_input_data
        
      rescue => e
        task.mark_failed(e.message)
        # Restore original input_data in case of failure
        task.input_data = original_input_data if defined?(original_input_data)
      end
      
      # Add task output to workflow variables for variable resolution
      if task.status == :completed
        @workflow.variables.merge!(task.output_data)
        # Also store task output by task_id for reference
        @workflow.variables[task.task_id] = task.output_data
      end
    end

    def execute_llm_task(task)
      # Extract prompt from task input data
      prompt = task.input_data[:prompt] || task.input_data['prompt']
      raise Rdawn::Errors::TaskExecutionError, "No prompt found in task input data" unless prompt
      
      # Extract model parameters if provided
      model_params = task.input_data[:model_params] || task.input_data['model_params'] || {}
      
      # Execute the LLM call
      response = @llm_interface.execute_llm_call(prompt: prompt, model_params: model_params)
      
      {
        task_id: task.task_id,
        executed_at: Time.now,
        input_processed: task.input_data,
        llm_response: response,
        type: :llm_task
      }
    end

    def execute_tool_task(task)
      # Execute the tool
      response = Rdawn::ToolRegistry.execute(task.tool_name, task.input_data)
      
      {
        task_id: task.task_id,
        executed_at: Time.now,
        input_processed: task.input_data,
        tool_response: response,
        tool_name: task.tool_name,
        type: :tool_task
      }
    end

    def execute_direct_handler_task(task)
      # Execute the handler directly
      handler_result = execute_handler(task.handler, task.input_data, @workflow.variables)
      
      {
        task_id: task.task_id,
        executed_at: Time.now,
        input_processed: task.input_data,
        handler_result: handler_result,
        handler_info: task.handler_description,
        type: :direct_handler_task
      }
    end

    def execute_mcp_task(task)
      # Execute an MCP task
      server_name = task.mcp_server_name
      tool_name = task.mcp_tool_name
      arguments = task.input_data
      
      # Check if async execution is requested
      if task.respond_to?(:async_execution) && task.async_execution
        # Execute asynchronously using MCPManager
        require_relative 'mcp_manager'
        future = Rdawn::MCPManager.execute_tool_async(server_name, tool_name, arguments)
        
        # Wait for the result (with timeout)
        timeout = task.respond_to?(:timeout) ? task.timeout : 30
        mcp_result = future.value!(timeout)
      else
        # Execute synchronously
        require_relative 'mcp_manager'
        mcp_result = Rdawn::MCPManager.execute_tool(server_name, tool_name, arguments)
      end
      
      {
        task_id: task.task_id,
        executed_at: Time.now,
        input_processed: task.input_data,
        mcp_result: mcp_result,
        server_name: server_name,
        tool_name: tool_name,
        type: :mcp_task
      }
    end

    def execute_handler(handler, input_data, workflow_variables)
      # Get the arity from the handler or its call method
      arity = get_handler_arity(handler)
      
      # Execute the handler with appropriate parameters based on its arity
      case arity
      when 0
        # Handler takes no parameters
        handler.call
      when 1
        # Handler takes input data only
        handler.call(input_data)
      when 2
        # Handler takes input data and workflow variables
        handler.call(input_data, workflow_variables)
      else
        # Handler takes multiple parameters, try to call with keyword arguments
        if input_data.is_a?(Hash) && workflow_variables.is_a?(Hash)
          # Merge input data and workflow variables for keyword arguments
          combined_data = workflow_variables.merge(input_data)
          handler.call(**combined_data)
        else
          # Fall back to positional arguments
          handler.call(input_data, workflow_variables)
        end
      end
    rescue ArgumentError => e
      # If the handler expects keyword arguments, try that approach
      if input_data.is_a?(Hash) && e.message.include?('missing keyword')
        begin
          handler.call(**input_data)
        rescue ArgumentError
          # If keyword arguments also fail, try with workflow variables merged
          if workflow_variables.is_a?(Hash)
            combined_data = workflow_variables.merge(input_data)
            handler.call(**combined_data)
          else
            raise e
          end
        end
      else
        raise e
      end
    end

    def get_handler_arity(handler)
      # Get arity from handler or its call method
      if handler.respond_to?(:arity)
        handler.arity
      elsif handler.respond_to?(:call)
        handler.method(:call).arity
      else
        1 # Default to 1 parameter if we can't determine arity
      end
    end

    def simulate_task_execution(task)
      # Simple simulation - just return basic output
      # This is a placeholder that will be replaced with actual execution logic
      {
        task_id: task.task_id,
        executed_at: Time.now,
        input_processed: task.input_data,
        simulated: true,
        type: :simulated_task
      }
    end
  end
end 