# frozen_string_literal: true

require 'singleton'
require_relative 'tools/mcp_task_executor'
require_relative 'tool_registry'

module Rdawn
  class MCPManager
    include Singleton
    
    attr_reader :executor
    
    def initialize
      @executor = Tools::MCPTaskExecutor.new
      @auto_register = true
    end
    
    def register_server(server_name, config)
      # Register an MCP server and optionally auto-register its tools.
      #
      # Args:
      #   server_name (String): Unique name for the server
      #   config (Hash): Server configuration
      #     - command (String): Command to run the server
      #     - args (Array): Arguments for the command
      #     - env (Hash): Environment variables
      #     - timeout (Integer): Request timeout in seconds
      #     - auto_register_tools (Boolean): Whether to auto-register tools (default: true)
      #
      # Example:
      #   MCPManager.instance.register_server('filesystem', {
      #     command: 'npx',
      #     args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
      #     auto_register_tools: true
      #   })
      @executor.register_server(server_name, config)
      
      # Auto-register tools if requested
      if config.fetch(:auto_register_tools, @auto_register)
        auto_register_server_tools(server_name)
      end
      
      Rails.logger.info "MCP server '#{server_name}' registered successfully" if defined?(Rails)
    end
    
    def unregister_server(server_name)
      # Unregister an MCP server and remove its tools from the registry.
      #
      # Args:
      #   server_name (String): Name of the server to unregister
      remove_server_tools(server_name)
      @executor.unregister_server(server_name)
    end
    
    def execute_tool(server_name, tool_name, arguments = {})
      # Execute an MCP tool directly.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #   tool_name (String): Name of the tool to execute
      #   arguments (Hash): Arguments for the tool
      #
      # Returns:
      #   Hash: The tool execution result
      @executor.execute_sync(server_name, tool_name, arguments)
    end
    
    def execute_tool_async(server_name, tool_name, arguments = {})
      # Execute an MCP tool asynchronously.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #   tool_name (String): Name of the tool to execute
      #   arguments (Hash): Arguments for the tool
      #
      # Returns:
      #   Concurrent::Future: A future that will resolve to the tool result
      @executor.execute_async(server_name, tool_name, arguments)
    end
    
    def list_servers
      # List all registered MCP servers.
      #
      # Returns:
      #   Array: List of server names
      @executor.registered_servers
    end
    
    def list_server_tools(server_name)
      # List all tools available on an MCP server.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #
      # Returns:
      #   Array: List of available tool names
      @executor.list_server_tools(server_name)
    end
    
    def list_server_resources(server_name)
      # List all resources available on an MCP server.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #
      # Returns:
      #   Array: List of available resource URIs
      @executor.list_server_resources(server_name)
    end
    
    def read_server_resource(server_name, uri)
      # Read a resource from an MCP server.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #   uri (String): URI of the resource to read
      #
      # Returns:
      #   Hash: The resource content
      @executor.read_server_resource(server_name, uri)
    end
    
    def get_server_capabilities(server_name)
      # Get the capabilities of an MCP server.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #
      # Returns:
      #   Hash: Server capabilities (tools, resources, prompts)
      @executor.get_server_capabilities(server_name)
    end
    
    def server_connected?(server_name)
      # Check if an MCP server is connected.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #
      # Returns:
      #   Boolean: True if connected, false otherwise
      @executor.server_connected?(server_name)
    end
    
    def shutdown
      # Shutdown the MCP manager and disconnect all servers.
      @executor.shutdown
    end
    
    def auto_register_all_tools
      # Auto-register tools for all registered servers.
      list_servers.each do |server_name|
        auto_register_server_tools(server_name)
      end
    end
    
    # Class methods for easier access
    def self.register_server(server_name, config)
      instance.register_server(server_name, config)
    end
    
    def self.unregister_server(server_name)
      instance.unregister_server(server_name)
    end
    
    def self.execute_tool(server_name, tool_name, arguments = {})
      instance.execute_tool(server_name, tool_name, arguments)
    end
    
    def self.execute_tool_async(server_name, tool_name, arguments = {})
      instance.execute_tool_async(server_name, tool_name, arguments)
    end
    
    def self.list_servers
      instance.list_servers
    end
    
    def self.shutdown
      instance.shutdown
    end
    
    # Configuration methods
    def self.configure
      yield(instance) if block_given?
    end
    
    def set_auto_register(enabled)
      @auto_register = enabled
    end
    
    private
    
    def auto_register_server_tools(server_name)
      # Auto-register all tools from an MCP server with the ToolRegistry.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      begin
        tools = @executor.list_server_tools(server_name)
        
        tools.each do |tool_name|
          # Create a unique tool name for the registry
          registry_tool_name = "mcp_#{server_name}_#{tool_name}"
          
          # Create a wrapper that can be registered with ToolRegistry
          tool_wrapper = @executor.create_tool_registry_wrapper(server_name, tool_name)
          
          # Register with ToolRegistry
          ToolRegistry.register(registry_tool_name, tool_wrapper)
          
          Rails.logger.debug "Auto-registered MCP tool: #{registry_tool_name}" if defined?(Rails)
        end
        
        Rails.logger.info "Auto-registered #{tools.length} tools from MCP server '#{server_name}'" if defined?(Rails)
        
      rescue => e
        Rails.logger.error "Failed to auto-register tools for MCP server '#{server_name}': #{e.message}" if defined?(Rails)
      end
    end
    
    def remove_server_tools(server_name)
      # Remove all tools for a server from the ToolRegistry.
      #
      # Args:
      #   server_name (String): Name of the server
      begin
        tools = @executor.list_server_tools(server_name)
        
        tools.each do |tool_name|
          registry_tool_name = "mcp_#{server_name}_#{tool_name}"
          
          if ToolRegistry.tool_exists?(registry_tool_name)
            ToolRegistry.unregister(registry_tool_name)
            Rails.logger.debug "Removed MCP tool: #{registry_tool_name}" if defined?(Rails)
          end
        end
        
        Rails.logger.info "Removed tools for MCP server '#{server_name}'" if defined?(Rails)
        
      rescue => e
        Rails.logger.error "Failed to remove tools for MCP server '#{server_name}': #{e.message}" if defined?(Rails)
      end
    end
  end
end 