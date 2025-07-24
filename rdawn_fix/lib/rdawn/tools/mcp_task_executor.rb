# frozen_string_literal: true

require 'concurrent'
require_relative 'mcp_tool'

module Rdawn
  module Tools
    class MCPTaskExecutor
      attr_reader :mcp_servers, :thread_pool
      
      def initialize(thread_pool_size: 5)
        @mcp_servers = {}
        @thread_pool = Concurrent::ThreadPoolExecutor.new(
          min_threads: 1,
          max_threads: thread_pool_size,
          max_queue: 100
        )
        @connection_mutex = Mutex.new
      end
      
      def register_server(server_name, config)
        # Register an MCP server with the executor.
        #
        # Args:
        #   server_name (String): Unique name for the server
        #   config (Hash): Server configuration
        #     - command (String): Command to run the server
        #     - args (Array): Arguments for the command
        #     - env (Hash): Environment variables
        #     - timeout (Integer): Request timeout in seconds
        #
        # Example:
        #   register_server('filesystem', {
        #     command: 'npx',
        #     args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        #     env: {},
        #     timeout: 30
        #   })
        @connection_mutex.synchronize do
          @mcp_servers[server_name] = {
            config: config,
            tool: nil,
            connected: false
          }
        end
      end
      
      def unregister_server(server_name)
        @connection_mutex.synchronize do
          if @mcp_servers[server_name]
            # Disconnect if connected
            @mcp_servers[server_name][:tool]&.disconnect
            @mcp_servers[server_name] = nil
          end
        end
      end
      
      def execute_async(server_name, tool_name, arguments = {})
        # Execute an MCP tool asynchronously.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #   tool_name (String): Name of the tool to execute
        #   arguments (Hash): Arguments for the tool
        #
        # Returns:
        #   Concurrent::Future: A future that will resolve to the tool result
        Concurrent::Future.execute(executor: @thread_pool) do
          execute_sync(server_name, tool_name, arguments)
        end
      end
      
      def execute_sync(server_name, tool_name, arguments = {})
        # Execute an MCP tool synchronously.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #   tool_name (String): Name of the tool to execute
        #   arguments (Hash): Arguments for the tool
        #
        # Returns:
        #   Hash: The tool execution result
        mcp_tool = get_or_create_tool(server_name)
        
        # Execute the tool
        result = mcp_tool.call_tool(tool_name, arguments)
        
        {
          server_name: server_name,
          tool_name: tool_name,
          arguments: arguments,
          result: result,
          executed_at: Time.now,
          type: :mcp_tool
        }
      end
      
      def list_server_tools(server_name)
        # List all tools available on an MCP server.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #
        # Returns:
        #   Array: List of available tool names
        mcp_tool = get_or_create_tool(server_name)
        mcp_tool.list_tools
      end
      
      def list_server_resources(server_name)
        # List all resources available on an MCP server.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #
        # Returns:
        #   Array: List of available resource URIs
        mcp_tool = get_or_create_tool(server_name)
        mcp_tool.list_resources
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
        mcp_tool = get_or_create_tool(server_name)
        mcp_tool.read_resource(uri)
      end
      
      def get_server_capabilities(server_name)
        # Get the capabilities of an MCP server.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #
        # Returns:
        #   Hash: Server capabilities (tools, resources, prompts)
        mcp_tool = get_or_create_tool(server_name)
        mcp_tool.capabilities
      end
      
      def shutdown
        # Shutdown the executor and disconnect all servers.
        @connection_mutex.synchronize do
          @mcp_servers.each do |_, server_info|
            server_info[:tool]&.disconnect
          end
          @mcp_servers.clear
        end
        
        @thread_pool.shutdown
        @thread_pool.wait_for_termination(30)
      end
      
      def registered_servers
        @mcp_servers.keys
      end
      
      def server_connected?(server_name)
        @mcp_servers[server_name]&.dig(:connected) || false
      end
      
      # Create a tool registry compatible wrapper
      def create_tool_registry_wrapper(server_name, tool_name)
        # Create a tool that can be registered with Rdawn::ToolRegistry.
        #
        # Args:
        #   server_name (String): Name of the registered MCP server
        #   tool_name (String): Name of the tool on the server
        #
        # Returns:
        #   Proc: A proc that can be registered with ToolRegistry
        #
        # Example:
        #   executor = MCPTaskExecutor.new
        #   executor.register_server('filesystem', config)
        #   
        #   fs_tool = executor.create_tool_registry_wrapper('filesystem', 'list_files')
        #   Rdawn::ToolRegistry.register('mcp_list_files', fs_tool)
        proc do |input_data|
          # Handle both sync and async execution
          if input_data.is_a?(Hash) && input_data[:async]
            # Return a future for async execution
            execute_async(server_name, tool_name, input_data)
          else
            # Execute synchronously
            execute_sync(server_name, tool_name, input_data)
          end
        end
      end
      
      private
      
      def get_or_create_tool(server_name)
        server_info = @mcp_servers[server_name]
        
        unless server_info
          raise Rdawn::Errors::ToolNotFoundError, "MCP server '#{server_name}' not registered"
        end
        
        @connection_mutex.synchronize do
          unless server_info[:tool] && server_info[:connected]
            # Create new tool instance
            config = server_info[:config]
            server_info[:tool] = MCPTool.new(
              server_name: server_name,
              command: config[:command],
              args: config[:args] || [],
              env: config[:env] || {},
              timeout: config[:timeout] || 30
            )
            
            # Connect to server
            server_info[:tool].connect
            server_info[:connected] = true
          end
          
          server_info[:tool]
        end
      end
    end
  end
end 