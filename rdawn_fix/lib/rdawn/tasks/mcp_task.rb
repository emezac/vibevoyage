# frozen_string_literal: true

module Rdawn
  module Tasks
    class MCPTask < Rdawn::Task
      attr_accessor :mcp_server_name, :mcp_tool_name, :async_execution, :timeout
      
      def initialize(task_id:, name:, mcp_server_name:, mcp_tool_name:, input_data: {}, 
                     async_execution: false, timeout: 30, **options)
        super(task_id: task_id, name: name, input_data: input_data, **options)
        
        @mcp_server_name = mcp_server_name
        @mcp_tool_name = mcp_tool_name
        @async_execution = async_execution
        @timeout = timeout
        
        validate_mcp_config!
      end
      
      def is_mcp_task
        true
      end
      
      def to_h
        super.merge(
          mcp_server_name: @mcp_server_name,
          mcp_tool_name: @mcp_tool_name,
          async_execution: @async_execution,
          timeout: @timeout,
          task_type: 'mcp_task'
        )
      end
      
      def task_description
        "MCP Task: #{@mcp_server_name}/#{@mcp_tool_name}" + 
        (@async_execution ? " (async)" : " (sync)")
      end
      
      private
      
      def validate_mcp_config!
        if @mcp_server_name.nil? || @mcp_server_name.empty?
          raise ArgumentError, "MCP server name cannot be nil or empty"
        end
        
        if @mcp_tool_name.nil? || @mcp_tool_name.empty?
          raise ArgumentError, "MCP tool name cannot be nil or empty"
        end
        
        unless @timeout.is_a?(Integer) && @timeout > 0
          raise ArgumentError, "Timeout must be a positive integer"
        end
      end
    end
  end
end 