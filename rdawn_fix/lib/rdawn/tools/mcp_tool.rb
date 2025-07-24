# frozen_string_literal: true

require 'json'
require 'open3'
require 'concurrent'
require 'timeout'

module Rdawn
  module Tools
    class MCPTool
      attr_reader :server_name, :command, :args, :env, :capabilities
      
      def initialize(server_name:, command:, args: [], env: {}, timeout: 30)
        @server_name = server_name
        @command = command
        @args = args
        @env = env
        @timeout = timeout
        @capabilities = {}
        @tools = {}
        @resources = {}
        @prompts = {}
        @next_request_id = 1
        @connection_mutex = Mutex.new
        @stdin = nil
        @stdout = nil
        @stderr = nil
        @wait_thread = nil
        @connected = false
      end
      
      def connect
        @connection_mutex.synchronize do
          return if @connected
          
          begin
            # Start the MCP server process
            @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(@env, @command, *@args)
            
            # Initialize the MCP protocol
            initialize_protocol
            
            # Load capabilities
            load_capabilities
            
            @connected = true
            ::Rails.logger.info "MCP server '#{@server_name}' connected successfully" if defined?(Rails)
            
          rescue => e
            disconnect
            raise Rdawn::Errors::TaskExecutionError, "Failed to connect to MCP server '#{@server_name}': #{e.message}"
          end
        end
      end
      
      def disconnect
        @connection_mutex.synchronize do
          return unless @connected
          
          begin
            # Send shutdown notification
            send_notification('shutdown') if @stdin && !@stdin.closed?
            
            # Close streams
            @stdin&.close
            @stdout&.close
            @stderr&.close
            
            # Terminate process
            @wait_thread&.value
            
          rescue => e
            ::Rails.logger.warn "Error during MCP server disconnect: #{e.message}" if defined?(Rails)
          ensure
            @stdin = nil
            @stdout = nil
            @stderr = nil
            @wait_thread = nil
            @connected = false
          end
        end
      end
      
      def connected?
        @connected
      end
      
      def list_tools
        ensure_connected
        
        response = send_request('tools/list')
        
        if response['result'] && response['result']['tools']
          @tools = response['result']['tools'].index_by { |tool| tool['name'] }
          @tools.keys
        else
          []
        end
      end
      
      def call_tool(tool_name, arguments = {})
        ensure_connected
        
        unless @tools.key?(tool_name)
          raise Rdawn::Errors::ToolNotFoundError, "Tool '#{tool_name}' not found on MCP server '#{@server_name}'"
        end
        
        response = send_request('tools/call', {
          name: tool_name,
          arguments: arguments
        })
        
        if response['result']
          parse_tool_response(response['result'])
        else
          raise Rdawn::Errors::TaskExecutionError, "Tool call failed: #{response['error']}"
        end
      end
      
      def list_resources
        ensure_connected
        
        response = send_request('resources/list')
        
        if response['result'] && response['result']['resources']
          @resources = response['result']['resources'].index_by { |resource| resource['uri'] }
          @resources.keys
        else
          []
        end
      end
      
      def read_resource(uri)
        ensure_connected
        
        response = send_request('resources/read', { uri: uri })
        
        if response['result']
          response['result']
        else
          raise Rdawn::Errors::TaskExecutionError, "Resource read failed: #{response['error']}"
        end
      end
      
      def list_prompts
        ensure_connected
        
        response = send_request('prompts/list')
        
        if response['result'] && response['result']['prompts']
          @prompts = response['result']['prompts'].index_by { |prompt| prompt['name'] }
          @prompts.keys
        else
          []
        end
      end
      
      def get_prompt(name, arguments = {})
        ensure_connected
        
        response = send_request('prompts/get', {
          name: name,
          arguments: arguments
        })
        
        if response['result']
          response['result']
        else
          raise Rdawn::Errors::TaskExecutionError, "Prompt get failed: #{response['error']}"
        end
      end
      
      # Execute method for ToolRegistry compatibility
      def execute(input_data = {})
        # Handle different input formats
        if input_data.is_a?(Hash)
          tool_name = input_data['tool_name'] || input_data[:tool_name]
          arguments = input_data['arguments'] || input_data[:arguments] || {}
          
          if tool_name
            call_tool(tool_name, arguments)
          else
            # If no specific tool, list available tools
            { available_tools: list_tools }
          end
        else
          { error: 'Invalid input format for MCP tool' }
        end
      end
      
      private
      
      def initialize_protocol
        # Send initialization request
        init_response = send_request('initialize', {
          protocolVersion: '2025-01-27',
          capabilities: {
            tools: {},
            resources: {},
            prompts: {}
          },
          clientInfo: {
            name: 'rdawn',
            version: Rdawn::VERSION
          }
        })
        
        unless init_response['result']
          raise Rdawn::Errors::TaskExecutionError, "MCP initialization failed: #{init_response['error']}"
        end
        
        # Send initialized notification
        send_notification('initialized')
      end
      
      def load_capabilities
        # Load server capabilities
        @capabilities = {
          tools: list_tools,
          resources: list_resources,
          prompts: list_prompts
        }
      end
      
      def send_request(method, params = {})
        ensure_connected
        
        request_id = @next_request_id
        @next_request_id += 1
        
        request = {
          jsonrpc: '2.0',
          id: request_id,
          method: method,
          params: params
        }
        
        # Send request
        request_json = JSON.generate(request)
        @stdin.puts(request_json)
        @stdin.flush
        
        # Read response with timeout
        response_line = nil
        Timeout.timeout(@timeout) do
          response_line = @stdout.gets
        end
        
        unless response_line
          raise Rdawn::Errors::TaskExecutionError, "No response from MCP server"
        end
        
        JSON.parse(response_line.strip)
        
      rescue Timeout::Error
        raise Rdawn::Errors::TaskExecutionError, "MCP request timeout after #{@timeout} seconds"
      rescue JSON::ParserError => e
        raise Rdawn::Errors::TaskExecutionError, "Invalid JSON response from MCP server: #{e.message}"
      end
      
      def send_notification(method, params = {})
        return unless @stdin && !@stdin.closed?
        
        notification = {
          jsonrpc: '2.0',
          method: method,
          params: params
        }
        
        notification_json = JSON.generate(notification)
        @stdin.puts(notification_json)
        @stdin.flush
      end
      
      def parse_tool_response(result)
        if result['content']
          # Extract content from MCP response
          content = result['content']
          
          if content.is_a?(Array)
            # Handle multiple content items
            content.map { |item| parse_content_item(item) }.join('\n')
          elsif content.is_a?(Hash)
            parse_content_item(content)
          else
            content.to_s
          end
        else
          result
        end
      end
      
      def parse_content_item(item)
        case item['type']
        when 'text'
          item['text']
        when 'image'
          "[Image: #{item['data']}]"
        when 'resource'
          "[Resource: #{item['resource']}]"
        else
          item.to_s
        end
      end
      
      def ensure_connected
        connect unless connected?
      end
    end
  end
end 