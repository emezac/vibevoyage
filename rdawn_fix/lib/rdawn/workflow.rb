# frozen_string_literal: true

module Rdawn
  class Workflow
    attr_accessor :workflow_id, :name, :status, :tasks, :variables

    def initialize(workflow_id:, name:)
      @workflow_id = workflow_id
      @name = name
      @status = :pending
      @tasks = {}
      @variables = {}
    end

    def add_task(task)
      @tasks[task.task_id] = task
    end

    def get_task(task_id)
      @tasks[task_id]
    end
  end
end
