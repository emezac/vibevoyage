# frozen_string_literal: true

require 'singleton'

module Rdawn
  class ToolRegistry
    include Singleton

    def initialize
      @tools = {}
    end

    def register(name, tool_object)
      validate_tool_name!(name)
      validate_tool_object!(tool_object)
      
      @tools[name.to_s] = tool_object
    end

    def execute(name, input_data = {})
      tool_name = name.to_s
      tool = @tools[tool_name]
      
      raise Rdawn::Errors::ToolNotFoundError, "Tool '#{tool_name}' not found" unless tool

      begin
        case tool
        when Proc, Method
          # Execute callable objects directly
          execute_callable(tool, input_data)
        when Class
          # Instantiate class and call execute method
          execute_class_tool(tool, input_data)
        else
          # Assume it's an object with an execute method
          execute_object_tool(tool, input_data)
        end
      rescue => e
        raise Rdawn::Errors::TaskExecutionError, "Tool '#{tool_name}' execution failed: #{e.message}"
      end
    end

    def registered_tools
      @tools.keys
    end

    def tool_exists?(name)
      @tools.key?(name.to_s)
    end

    def unregister(name)
      @tools.delete(name.to_s)
    end

    def clear_all
      @tools.clear
    end

    # Class methods for easier access
    def self.register(name, tool_object)
      instance.register(name, tool_object)
    end

    def self.execute(name, input_data = {})
      instance.execute(name, input_data)
    end

    def self.registered_tools
      instance.registered_tools
    end

    def self.tool_exists?(name)
      instance.tool_exists?(name)
    end

    def self.unregister(name)
      instance.unregister(name)
    end

    def self.clear_all
      instance.clear_all
    end

    private

    def validate_tool_name!(name)
      raise ArgumentError, "Tool name cannot be nil" if name.nil?
      raise ArgumentError, "Tool name cannot be empty" if name.to_s.strip.empty?
    end

    def validate_tool_object!(tool_object)
      raise ArgumentError, "Tool object cannot be nil" if tool_object.nil?
      
      # Check if it's a valid tool type
      valid_types = [Proc, Method, Class]
      is_valid_type = valid_types.any? { |type| tool_object.is_a?(type) }
      has_execute_method = tool_object.respond_to?(:execute)
      
      unless is_valid_type || has_execute_method
        raise ArgumentError, "Tool must be a Proc, Method, Class, or respond to :execute"
      end
    end

    def execute_callable(tool, input_data)
      # Handle Proc and Method objects
      if tool.arity == 0
        tool.call
      elsif expects_keyword_args?(tool) && input_data.is_a?(Hash)
        # Handle keyword arguments first, regardless of arity
        tool.call(**input_data)
      elsif tool.arity == 1
        tool.call(input_data)
      else
        # For tools that accept multiple arguments, pass input_data as keyword arguments
        if input_data.is_a?(Hash)
          tool.call(**input_data)
        else
          tool.call(input_data)
        end
      end
    end

    def expects_keyword_args?(tool)
      # Check if the tool's parameters include keyword arguments
      tool.parameters.any? { |param| [:keyreq, :key].include?(param[0]) }
    end

    def execute_class_tool(tool_class, input_data)
      # Instantiate the class and call execute
      tool_instance = tool_class.new
      
      if tool_instance.respond_to?(:execute)
        method = tool_instance.method(:execute)
        if method.arity == 0
          tool_instance.execute
        else
          tool_instance.execute(input_data)
        end
      else
        raise ArgumentError, "Tool class must have an execute method"
      end
    end

    def execute_object_tool(tool_object, input_data)
      # Handle objects that respond to execute
      method = tool_object.method(:execute)
      if method.arity == 0
        tool_object.execute
      else
        tool_object.execute(input_data)
      end
    end
  end
end 