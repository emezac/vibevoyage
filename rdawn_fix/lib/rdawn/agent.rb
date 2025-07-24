# frozen_string_literal: true

require_relative 'workflow_engine'

module Rdawn
  class Agent
    def initialize(workflow:, llm_interface:)
      @workflow = workflow
      @llm_interface = llm_interface
    end

    def run(initial_input: {})
      engine = WorkflowEngine.new(workflow: @workflow, llm_interface: @llm_interface)
      engine.run(initial_input: initial_input)
    end
  end
end
