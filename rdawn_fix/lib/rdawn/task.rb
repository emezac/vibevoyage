# frozen_string_literal: true

module Rdawn
  class Task
    attr_accessor :task_id, :name, :status, :input_data, :output_data,
                  :is_llm_task, :tool_name, :max_retries, :retry_count,
                  :next_task_id_on_success, :next_task_id_on_failure, :condition

    def initialize(task_id:, name:, input_data: {}, is_llm_task: false, tool_name: nil, max_retries: 0)
      @task_id = task_id
      @name = name
      @status = :pending
      @input_data = input_data
      @output_data = {}
      @is_llm_task = is_llm_task
      @tool_name = tool_name
      @max_retries = max_retries
      @retry_count = 0
    end

    def mark_running
      @status = :running
    end

    def mark_completed(output)
      @status = :completed
      @output_data = output
    end

    def mark_failed(error)
      @status = :failed
      @output_data = { error: error }
    end

    def to_h
      {
        task_id: @task_id,
        name: @name,
        status: @status,
        input_data: @input_data,
        output_data: @output_data,
        is_llm_task: @is_llm_task,
        tool_name: @tool_name,
        max_retries: @max_retries,
        retry_count: @retry_count,
        next_task_id_on_success: @next_task_id_on_success,
        next_task_id_on_failure: @next_task_id_on_failure,
        condition: @condition
      }
    end
  end
end
