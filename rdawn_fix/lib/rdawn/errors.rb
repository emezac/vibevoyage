# frozen_string_literal: true

module Rdawn
  module Errors
    class RdawnError < StandardError; end
    class ConfigurationError < RdawnError; end
    class TaskExecutionError < RdawnError; end
    class ToolNotFoundError < RdawnError; end
    class VariableResolutionError < RdawnError; end
  end
end
