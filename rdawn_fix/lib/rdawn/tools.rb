# frozen_string_literal: true

require_relative 'tools/vector_store_tool'
require_relative 'tools/file_upload_tool'
require_relative 'tools/file_search_tool'
require_relative 'tools/web_search_tool'
require_relative 'tools/markdown_tool'
require_relative 'tools/cron_tool'

module Rdawn
  module Tools
    # Register all advanced tools in the ToolRegistry
    def self.register_advanced_tools(api_key: nil)
      # Register all advanced tools in the ToolRegistry.
      #
      # Args:
      #   api_key (String): Optional API key for OpenAI tools
      
      # Vector Store Tools
      Rdawn::ToolRegistry.register('vector_store_create', proc do |input|
        tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
        tool.create_vector_store(
          name: input['name'] || input[:name],
          file_ids: input['file_ids'] || input[:file_ids] || [],
          expires_after: input['expires_after'] || input[:expires_after]
        )
      end)

      Rdawn::ToolRegistry.register('vector_store_get', proc do |input|
        tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
        tool.get_vector_store(input['vector_store_id'] || input[:vector_store_id])
      end)

      Rdawn::ToolRegistry.register('vector_store_list', proc do |input|
        tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
        tool.list_vector_stores(
          limit: input['limit'] || input[:limit] || 20,
          order: input['order'] || input[:order] || 'desc'
        )
      end)

      Rdawn::ToolRegistry.register('vector_store_delete', proc do |input|
        tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
        tool.delete_vector_store(input['vector_store_id'] || input[:vector_store_id])
      end)

      Rdawn::ToolRegistry.register('vector_store_add_file', proc do |input|
        tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
        tool.add_file_to_vector_store(
          input['vector_store_id'] || input[:vector_store_id],
          input['file_id'] || input[:file_id]
        )
      end)

      # File Upload Tools
      Rdawn::ToolRegistry.register('file_upload', proc do |input|
        tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
        tool.upload_file(
          file_path: input['file_path'] || input[:file_path],
          purpose: input['purpose'] || input[:purpose] || 'assistants'
        )
      end)

      Rdawn::ToolRegistry.register('file_upload_from_url', proc do |input|
        tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
        tool.upload_file_from_url(
          url: input['url'] || input[:url],
          purpose: input['purpose'] || input[:purpose] || 'assistants'
        )
      end)

      Rdawn::ToolRegistry.register('file_get_info', proc do |input|
        tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
        tool.get_file_info(input['file_id'] || input[:file_id])
      end)

      Rdawn::ToolRegistry.register('file_list', proc do |input|
        tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
        tool.list_files(
          purpose: input['purpose'] || input[:purpose],
          limit: input['limit'] || input[:limit] || 20
        )
      end)

      Rdawn::ToolRegistry.register('file_delete', proc do |input|
        tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
        tool.delete_file(input['file_id'] || input[:file_id])
      end)

      # File Search Tools
      Rdawn::ToolRegistry.register('file_search', proc do |input|
        tool = Rdawn::Tools::FileSearchTool.new(api_key: api_key)
        tool.search_files(
          query: input['query'] || input[:query],
          vector_store_ids: input['vector_store_ids'] || input[:vector_store_ids],
          max_results: input['max_results'] || input[:max_results] || 5,
          model: input['model'] || input[:model] || 'gpt-4o-mini'
        )
      end)

      Rdawn::ToolRegistry.register('file_search_with_context', proc do |input|
        tool = Rdawn::Tools::FileSearchTool.new(api_key: api_key)
        tool.search_with_context(
          query: input['query'] || input[:query],
          vector_store_ids: input['vector_store_ids'] || input[:vector_store_ids],
          context: input['context'] || input[:context],
          max_results: input['max_results'] || input[:max_results] || 5,
          model: input['model'] || input[:model] || 'gpt-4o-mini'
        )
      end)

      # Web Search Tools
      Rdawn::ToolRegistry.register('web_search', proc do |input|
        tool = Rdawn::Tools::WebSearchTool.new(api_key: api_key)
        tool.search(
          query: input['query'] || input[:query],
          context_size: input['context_size'] || input[:context_size] || 'medium',
          user_location: input['user_location'] || input[:user_location],
          model: input['model'] || input[:model] || 'gpt-4o'
        )
      end)

      Rdawn::ToolRegistry.register('web_search_news', proc do |input|
        tool = Rdawn::Tools::WebSearchTool.new(api_key: api_key)
        tool.search_news(
          query: input['query'] || input[:query],
          context_size: input['context_size'] || input[:context_size] || 'medium',
          model: input['model'] || input[:model] || 'gpt-4o'
        )
      end)

      Rdawn::ToolRegistry.register('web_search_recent', proc do |input|
        tool = Rdawn::Tools::WebSearchTool.new(api_key: api_key)
        tool.search_recent(
          query: input['query'] || input[:query],
          timeframe: input['timeframe'] || input[:timeframe] || 'today',
          context_size: input['context_size'] || input[:context_size] || 'medium',
          model: input['model'] || input[:model] || 'gpt-4o'
        )
      end)

      Rdawn::ToolRegistry.register('web_search_with_filters', proc do |input|
        tool = Rdawn::Tools::WebSearchTool.new(api_key: api_key)
        tool.search_with_filters(
          query: input['query'] || input[:query],
          filters: input['filters'] || input[:filters] || {},
          context_size: input['context_size'] || input[:context_size] || 'medium',
          model: input['model'] || input[:model] || 'gpt-4o'
        )
      end)

      # Markdown Tools
      Rdawn::ToolRegistry.register('markdown_generate', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.generate_markdown(
          prompt: input['prompt'] || input[:prompt],
          style: input['style'] || input[:style] || 'technical',
          model: input['model'] || input[:model] || 'gpt-4o-mini',
          length: input['length'] || input[:length] || 'medium'
        )
      end)

      Rdawn::ToolRegistry.register('markdown_edit', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.edit_markdown(
          markdown: input['markdown'] || input[:markdown],
          instructions: input['instructions'] || input[:instructions],
          model: input['model'] || input[:model] || 'gpt-4o-mini',
          preserve_style: input['preserve_style'] || input[:preserve_style] || true
        )
      end)

      Rdawn::ToolRegistry.register('markdown_to_html', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.markdown_to_html(
          markdown: input['markdown'] || input[:markdown],
          github_style: input['github_style'] || input[:github_style] || true,
          syntax_highlighting: input['syntax_highlighting'] || input[:syntax_highlighting] || true
        )
      end)

      Rdawn::ToolRegistry.register('markdown_format', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.format_markdown(
          markdown: input['markdown'] || input[:markdown],
          style: input['style'] || input[:style] || 'standard',
          line_length: input['line_length'] || input[:line_length] || 80
        )
      end)

      Rdawn::ToolRegistry.register('markdown_create_template', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.create_template(
          type: input['type'] || input[:type] || 'basic',
          title: input['title'] || input[:title] || '',
          author: input['author'] || input[:author] || '',
          tags: input['tags'] || input[:tags] || []
        )
      end)

      Rdawn::ToolRegistry.register('markdown_generate_toc', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.generate_toc(
          markdown: input['markdown'] || input[:markdown],
          max_depth: input['max_depth'] || input[:max_depth] || 3,
          style: input['style'] || input[:style] || 'bullet'
        )
      end)

      Rdawn::ToolRegistry.register('markdown_validate', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.validate_markdown(
          markdown: input['markdown'] || input[:markdown],
          strict: input['strict'] || input[:strict] || false
        )
      end)

      Rdawn::ToolRegistry.register('markdown_suggest_improvements', proc do |input|
        tool = Rdawn::Tools::MarkdownTool.new(api_key: api_key)
        tool.suggest_improvements(
          markdown: input['markdown'] || input[:markdown],
          focus: input['focus'] || input[:focus] || 'readability',
          model: input['model'] || input[:model] || 'gpt-4o-mini'
        )
      end)

      # Cron Tools
      Rdawn::ToolRegistry.register('cron_schedule_task', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.schedule_task(
          name: input['name'] || input[:name],
          cron_expression: input['cron_expression'] || input[:cron_expression],
          task_proc: input['task_proc'] || input[:task_proc],
          workflow_id: input['workflow_id'] || input[:workflow_id],
          tool_name: input['tool_name'] || input[:tool_name],
          input_data: input['input_data'] || input[:input_data] || {},
          options: input['options'] || input[:options] || {}
        )
      end)

      Rdawn::ToolRegistry.register('cron_schedule_once', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.schedule_once(
          name: input['name'] || input[:name],
          at_time: input['at_time'] || input[:at_time],
          task_proc: input['task_proc'] || input[:task_proc],
          workflow_id: input['workflow_id'] || input[:workflow_id],
          tool_name: input['tool_name'] || input[:tool_name],
          input_data: input['input_data'] || input[:input_data] || {},
          options: input['options'] || input[:options] || {}
        )
      end)

      Rdawn::ToolRegistry.register('cron_schedule_recurring', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.schedule_recurring(
          name: input['name'] || input[:name],
          interval: input['interval'] || input[:interval],
          task_proc: input['task_proc'] || input[:task_proc],
          workflow_id: input['workflow_id'] || input[:workflow_id],
          tool_name: input['tool_name'] || input[:tool_name],
          input_data: input['input_data'] || input[:input_data] || {},
          options: input['options'] || input[:options] || {}
        )
      end)

      Rdawn::ToolRegistry.register('cron_unschedule_job', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.unschedule_job(name: input['name'] || input[:name])
      end)

      Rdawn::ToolRegistry.register('cron_list_jobs', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.list_jobs
      end)

      Rdawn::ToolRegistry.register('cron_get_job', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.get_job(name: input['name'] || input[:name])
      end)

      Rdawn::ToolRegistry.register('cron_execute_job_now', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.execute_job_now(name: input['name'] || input[:name])
      end)

      Rdawn::ToolRegistry.register('cron_get_statistics', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.get_statistics
      end)

      Rdawn::ToolRegistry.register('cron_stop_scheduler', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.stop_scheduler
      end)

      Rdawn::ToolRegistry.register('cron_restart_scheduler', proc do |input|
        tool = Rdawn::Tools::CronTool.new
        tool.restart_scheduler
      end)
    end

    # Convenience methods for creating tool instances
    def self.vector_store_tool(api_key: nil)
      Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
    end

    def self.file_upload_tool(api_key: nil)
      Rdawn::Tools::FileUploadTool.new(api_key: api_key)
    end

    def self.file_search_tool(api_key: nil)
      Rdawn::Tools::FileSearchTool.new(api_key: api_key)
    end

    def self.web_search_tool(api_key: nil)
      Rdawn::Tools::WebSearchTool.new(api_key: api_key)
    end

    def self.markdown_tool(api_key: nil)
      Rdawn::Tools::MarkdownTool.new(api_key: api_key)
    end

    def self.cron_tool(options: {})
      Rdawn::Tools::CronTool.new(options)
    end

    # Create a complete RAG workflow
    def self.create_rag_workflow(name:, file_paths:, api_key: nil)
      # Create a complete RAG workflow with vector store, file upload, and search.
      #
      # Args:
      #   name (String): Name for the vector store
      #   file_paths (Array): Array of file paths to upload
      #   api_key (String): Optional API key for OpenAI
      #
      # Returns:
      #   Hash: Contains vector_store_id, file_ids, and search_tool
      vector_store_tool = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
      file_upload_tool = Rdawn::Tools::FileUploadTool.new(api_key: api_key)
      file_search_tool = Rdawn::Tools::FileSearchTool.new(api_key: api_key)

      # Upload files
      file_ids = file_paths.map do |file_path|
        result = file_upload_tool.upload_file(file_path: file_path)
        result[:id]
      end

      # Create vector store with uploaded files
      vector_store = vector_store_tool.create_vector_store(
        name: name,
        file_ids: file_ids
      )

      {
        vector_store_id: vector_store[:id],
        file_ids: file_ids,
        search_tool: file_search_tool,
        ready: true
      }
    end

    # Search across multiple vector stores
    def self.multi_store_search(query:, vector_store_ids:, max_results: 10, api_key: nil)
      # Search across multiple vector stores and combine results.
      #
      # Args:
      #   query (String): Search query
      #   vector_store_ids (Array): Array of vector store IDs
      #   max_results (Integer): Maximum results per store
      #   api_key (String): Optional API key for OpenAI
      #
      # Returns:
      #   Hash: Combined search results
      file_search_tool = Rdawn::Tools::FileSearchTool.new(api_key: api_key)
      
      file_search_tool.search_files(
        query: query,
        vector_store_ids: vector_store_ids,
        max_results: max_results
      )
    end

    # MCP Integration Methods
    def self.register_mcp_server(server_name, config)
      # Register an MCP server and auto-register its tools.
      #
      # Args:
      #   server_name (String): Unique name for the server
      #   config (Hash): Server configuration
      #
      # Example:
      #   Rdawn::Tools.register_mcp_server('filesystem', {
      #     command: 'npx',
      #     args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp']
      #   })
      require_relative 'mcp_manager'
      Rdawn::MCPManager.register_server(server_name, config)
    end

    def self.unregister_mcp_server(server_name)
      # Unregister an MCP server and remove its tools.
      #
      # Args:
      #   server_name (String): Name of the server to unregister
      require_relative 'mcp_manager'
      Rdawn::MCPManager.unregister_server(server_name)
    end

    def self.list_mcp_servers
      # List all registered MCP servers.
      #
      # Returns:
      #   Array: List of server names
      require_relative 'mcp_manager'
      Rdawn::MCPManager.list_servers
    end

    def self.list_mcp_server_tools(server_name)
      # List all tools available on an MCP server.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #
      # Returns:
      #   Array: List of available tool names
      require_relative 'mcp_manager'
      Rdawn::MCPManager.instance.list_server_tools(server_name)
    end

    def self.execute_mcp_tool(server_name, tool_name, arguments = {})
      # Execute an MCP tool directly.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #   tool_name (String): Name of the tool to execute
      #   arguments (Hash): Arguments for the tool
      #
      # Returns:
      #   Hash: The tool execution result
      require_relative 'mcp_manager'
      Rdawn::MCPManager.execute_tool(server_name, tool_name, arguments)
    end

    def self.execute_mcp_tool_async(server_name, tool_name, arguments = {})
      # Execute an MCP tool asynchronously.
      #
      # Args:
      #   server_name (String): Name of the registered MCP server
      #   tool_name (String): Name of the tool to execute
      #   arguments (Hash): Arguments for the tool
      #
      # Returns:
      #   Concurrent::Future: A future that will resolve to the tool result
      require_relative 'mcp_manager'
      Rdawn::MCPManager.execute_tool_async(server_name, tool_name, arguments)
    end

    def self.shutdown_mcp
      # Shutdown all MCP servers and connections.
      require_relative 'mcp_manager'
      Rdawn::MCPManager.shutdown
    end

    # Create a complete MCP workflow helper
    def self.create_mcp_workflow(server_configs:, workflow_name:)
      # Create a complete MCP workflow with multiple servers.
      #
      # Args:
      #   server_configs (Hash): Hash of server_name => config
      #   workflow_name (String): Name for the workflow
      #
      # Returns:
      #   Hash: Workflow configuration with registered servers
      #
      # Example:
      #   workflow = Rdawn::Tools.create_mcp_workflow(
      #     server_configs: {
      #       'filesystem' => {
      #         command: 'npx',
      #         args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp']
      #       },
      #       'web_search' => {
      #         command: 'python',
      #         args: ['./mcp_servers/web_search.py']
      #       }
      #     },
      #     workflow_name: 'Multi-Server Workflow'
      #   )
      require_relative 'mcp_manager'
      
      registered_servers = []
      
      server_configs.each do |server_name, config|
        Rdawn::MCPManager.register_server(server_name, config)
        registered_servers << server_name
      end
      
      {
        workflow_name: workflow_name,
        registered_servers: registered_servers,
        available_tools: registered_servers.map { |server_name|
          begin
            tools = Rdawn::MCPManager.instance.list_server_tools(server_name)
            { server_name => tools }
          rescue => e
            { server_name => "Error: #{e.message}" }
          end
        }.reduce(&:merge),
        ready: true
      }
    end
  end
end 