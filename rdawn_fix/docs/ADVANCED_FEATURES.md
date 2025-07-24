# Advanced Features Documentation

## Overview

This document describes the Advanced Features implementation for the `rdawn` framework, specifically focusing on **RAG (Retrieval-Augmented Generation)** and **Web Search** capabilities that were added in Phase 3.3.

## Features Implemented

### 1. Vector Store Management
- **VectorStoreTool**: Complete CRUD operations for OpenAI vector stores
- **File Management**: Upload, list, and delete files
- **Search Capabilities**: Semantic search through vector stores

### 2. RAG (Retrieval-Augmented Generation)
- **FileSearchTool**: Search through uploaded documents using vector stores
- **Context-aware Search**: Enhanced search with additional context
- **Multi-store Search**: Search across multiple vector stores simultaneously

### 3. Web Search Integration
- **WebSearchTool**: Real-time web search using OpenAI's web search API
- **Contextual Search**: Search with additional context and filters
- **News Search**: Specialized news search capabilities
- **Recent Search**: Time-constrained search functionality

### 4. Task Scheduling (CronTool)
- **CronTool**: Comprehensive task scheduling using rufus-scheduler
- **Cron Expressions**: Standard Unix cron expression support
- **One-Time Scheduling**: Tasks that run at specific future times
- **Recurring Intervals**: Simple interval-based scheduling (30s, 5m, 1h, etc.)
- **Tool Integration**: Schedule any rdawn tool to run automatically
- **Event Callbacks**: Monitor job lifecycle with custom callbacks
- **Statistics Tracking**: Detailed execution metrics and monitoring
- **Job Management**: List, inspect, execute, and cancel scheduled jobs

### 5. Enhanced LLM Interface
- **File Search Support**: Direct integration with vector stores
- **Web Search Support**: Built-in web search capabilities
- **Backward Compatibility**: Existing functionality remains unchanged

## Architecture

### Core Components

```
rdawn/
├── lib/rdawn/tools/
│   ├── vector_store_tool.rb      # Vector store CRUD operations
│   ├── file_upload_tool.rb       # File upload and management
│   ├── file_search_tool.rb       # RAG search functionality
│   ├── web_search_tool.rb        # Web search capabilities
│   ├── markdown_tool.rb          # AI-powered markdown generation/editing
│   └── cron_tool.rb              # Task scheduling with cron expressions
├── lib/rdawn/tools.rb            # Tool registry and convenience methods
└── lib/rdawn/llm_interface.rb    # Enhanced with RAG/Web search
```

### Data Flow

1. **RAG Workflow**:
   ```
   File Upload → Vector Store Creation → File Search → LLM Response
   ```

2. **Web Search Workflow**:
   ```
   Query → Web Search API → Results → LLM Response
   ```

3. **Cron Scheduling Workflow**:
   ```
   Schedule Definition → Cron Expression/Interval → Job Execution → Results/Monitoring
   ```

## Implementation Details

### Vector Store Operations

```ruby
# Create vector store
vector_store = Rdawn::Tools::VectorStoreTool.new(api_key: api_key)
store = vector_store.create_vector_store(
  name: "Knowledge Base",
  file_ids: ["file-123", "file-456"]
)

# Search files
search_tool = Rdawn::Tools::FileSearchTool.new(api_key: api_key)
results = search_tool.search_files(
  query: "What is machine learning?",
  vector_store_ids: [store[:id]],
  max_results: 5
)
```

### Enhanced LLM Interface

```ruby
# LLM with RAG support
llm = Rdawn::LLMInterface.new(
  api_key: api_key,
  use_file_search: true,
  vector_store_ids: ['vs_knowledge_base']
)

response = llm.execute_llm_call(
  prompt: "Explain our company policy on remote work"
)

# LLM with web search support
llm = Rdawn::LLMInterface.new(
  api_key: api_key,
  use_web_search: true,
  web_search_context_size: 'large'
)

response = llm.execute_llm_call(
  prompt: "What are the latest developments in AI?"
)
```

### Task Scheduling Operations

```ruby
# Initialize CronTool
cron_tool = Rdawn::Tools::CronTool.new

# Schedule recurring task with cron expression
cron_tool.schedule_task(
  name: 'daily_report',
  cron_expression: '0 9 * * *',  # Daily at 9 AM
  tool_name: 'web_search',
  input_data: { query: 'daily news' }
)

# Schedule one-time task
cron_tool.schedule_once(
  name: 'maintenance',
  at_time: '2025-01-01 02:00:00',
  task_proc: proc { |data| puts "Maintenance task executed" }
)

# Monitor scheduled jobs
jobs = cron_tool.list_jobs
stats = cron_tool.get_statistics
puts "Active jobs: #{stats[:active_jobs]}"
```

### Tool Registry Integration

```ruby
# Register all advanced tools
Rdawn::Tools.register_advanced_tools(api_key: ENV['OPENAI_API_KEY'])

# Use through workflow
workflow_data = {
  tasks: {
    'search_knowledge' => {
      type: 'tool',
      tool_name: 'file_search',
      input_data: {
        query: 'machine learning basics',
        vector_store_ids: ['vs_knowledge_base']
      }
    }
  }
}
```

## Workflow Integration

### RAG Workflow Example

```ruby
rag_workflow = {
  workflow_id: 'rag_demo',
  tasks: {
    'upload_files' => {
      type: 'tool',
      tool_name: 'file_upload',
      input_data: { file_path: '${file_path}' }
    },
    'create_vector_store' => {
      type: 'tool',
      tool_name: 'vector_store_create',
      input_data: {
        name: 'Knowledge Base',
        file_ids: ['${upload_files.id}']
      }
    },
    'search_files' => {
      type: 'tool',
      tool_name: 'file_search',
      input_data: {
        query: '${search_query}',
        vector_store_ids: ['${create_vector_store.id}']
      }
    },
    'generate_response' => {
      type: 'llm',
      input_data: {
        prompt: 'Based on: ${search_files.content}\n\nAnswer: ${search_query}'
      }
    }
  }
}
```

### Web Search Workflow Example

```ruby
web_search_workflow = {
  workflow_id: 'web_search_demo',
  tasks: {
    'search_web' => {
      type: 'tool',
      tool_name: 'web_search',
      input_data: {
        query: '${search_query}',
        context_size: 'large'
      }
    },
    'search_news' => {
      type: 'tool',
      tool_name: 'web_search_news',
      input_data: {
        query: '${search_query}'
      }
    },
    'combine_results' => {
      type: 'llm',
      input_data: {
        prompt: 'Web: ${search_web.content}\nNews: ${search_news.content}\n\nSummary:'
      }
    }
  }
}
```

## Rails Integration

### Controller Example

```ruby
class KnowledgeBaseController < ApplicationController
  def search
    workflow_data = {
      workflow_id: "kb_search_#{current_user.id}",
      tasks: {
        'search_knowledge' => {
          type: 'tool',
          tool_name: 'file_search',
          input_data: {
            query: params[:query],
            vector_store_ids: [company_vector_store_id]
          }
        },
        'web_search_fallback' => {
          type: 'tool',
          tool_name: 'web_search',
          input_data: { query: params[:query] },
          condition: { 'eq' => ['${search_knowledge.results.length}', 0] }
        }
      }
    }
    
    Rdawn::Rails::WorkflowJob.run_workflow_later(
      workflow_data: workflow_data,
      initial_input: { query: params[:query] }
    )
  end
end
```

## Configuration

### Environment Variables

```bash
# OpenAI API Key (required)
OPENAI_API_KEY=sk-...

# Optional: Alternative API key
RDAWN_LLM_API_KEY=sk-...
```

### Initializer (Rails)

```ruby
# config/initializers/rdawn.rb
Rdawn.configure do |config|
  config.llm_api_key = ENV['OPENAI_API_KEY']
  config.default_model = 'gpt-4o-mini'
end

# Register advanced tools
Rdawn::Tools.register_advanced_tools(api_key: ENV['OPENAI_API_KEY'])
```

## Available Tools

### Vector Store Tools
- `vector_store_create` - Create new vector store
- `vector_store_get` - Get vector store info
- `vector_store_list` - List all vector stores
- `vector_store_delete` - Delete vector store
- `vector_store_add_file` - Add file to vector store

### File Management Tools
- `file_upload` - Upload file to OpenAI
- `file_upload_from_url` - Upload file from URL
- `file_get_info` - Get file information
- `file_list` - List uploaded files
- `file_delete` - Delete uploaded file

### Search Tools
- `file_search` - Search through vector stores
- `file_search_with_context` - Search with additional context
- `web_search` - General web search
- `web_search_news` - News-specific search
- `web_search_recent` - Recent information search
- `web_search_with_filters` - Search with filters

## Convenience Methods

### Complete RAG Setup

```ruby
# Create complete RAG workflow
rag_setup = Rdawn::Tools.create_rag_workflow(
  name: 'Company Knowledge Base',
  file_paths: [
    'docs/handbook.pdf',
    'docs/policies.md',
    'docs/procedures.txt'
  ],
  api_key: ENV['OPENAI_API_KEY']
)

# Search the knowledge base
results = Rdawn::Tools.multi_store_search(
  query: 'remote work policy',
  vector_store_ids: [rag_setup[:vector_store_id]],
  max_results: 10
)
```

### Tool Instance Creation

```ruby
# Create tool instances
vector_tool = Rdawn::Tools.vector_store_tool(api_key: api_key)
file_tool = Rdawn::Tools.file_upload_tool(api_key: api_key)
search_tool = Rdawn::Tools.file_search_tool(api_key: api_key)
web_tool = Rdawn::Tools.web_search_tool(api_key: api_key)
markdown_tool = Rdawn::Tools.markdown_tool(api_key: api_key)
cron_tool = Rdawn::Tools.cron_tool
```

## Error Handling

### Common Errors

```ruby
begin
  results = file_search_tool.search_files(
    query: query,
    vector_store_ids: vector_store_ids
  )
rescue Rdawn::Errors::ConfigurationError => e
  # Handle configuration issues (missing API key, invalid parameters)
  puts "Configuration error: #{e.message}"
rescue Rdawn::Errors::TaskExecutionError => e
  # Handle execution failures (API errors, network issues)
  puts "Execution error: #{e.message}"
end
```

### Validation

- Vector store IDs must start with 'vs_'
- File upload size limits (512MB for assistants)
- Query length and content validation
- API key presence validation

## Performance Considerations

### Caching

```ruby
# Cache vector store IDs
def company_vector_store_id
  Rails.cache.fetch('company_vector_store_id', expires_in: 1.day) do
    # Create or retrieve vector store
    'vs_company_knowledge'
  end
end
```

### Batch Operations

```ruby
# Upload multiple files
file_ids = file_paths.map do |path|
  file_tool.upload_file(file_path: path)[:id]
end

# Create vector store with all files
vector_store = vector_tool.create_vector_store(
  name: 'Batch Upload',
  file_ids: file_ids
)
```

## Testing

### Test Structure

```ruby
# Core functionality tests: 113 passing
# - LLM Interface: 18 tests
# - Task Management: 5 tests
# - DirectHandlerTask: 24 tests
# - ToolRegistry: 20 tests
# - VariableResolver: 26 tests
# - WorkflowEngine: 19 tests
# - Workflow: 1 test
```

### Mock Testing

```ruby
# Mock vector store for testing
allow(Rdawn::Tools::VectorStoreTool).to receive(:new).and_return(mock_tool)
allow(mock_tool).to receive(:create_vector_store).and_return({
  id: 'vs_test_123',
  name: 'Test Store',
  status: 'completed'
})
```

## Future Enhancements

### Planned Features
1. **MCP Integration**: Model Context Protocol support
2. **Additional Providers**: Support for other vector store providers
3. **Advanced Search**: Hybrid search combining multiple strategies
4. **Caching Layer**: Built-in caching for frequent searches
5. **Batch Processing**: Bulk operations for large datasets

### Architecture Improvements
1. **Async Processing**: Background job integration
2. **Rate Limiting**: Built-in rate limiting for API calls
3. **Monitoring**: Search analytics and performance metrics
4. **Security**: Enhanced access controls and audit logging

## Conclusion

The Advanced Features implementation provides a comprehensive foundation for building RAG-enabled AI agents within the rdawn framework. The modular design allows for easy extension and integration with existing workflows while maintaining backward compatibility.

Key benefits:
- ✅ Complete RAG implementation
- ✅ Web search integration
- ✅ Rails-native design
- ✅ Tool registry system
- ✅ Backward compatibility
- ✅ Comprehensive error handling
- ✅ Performance optimizations

The implementation successfully transforms rdawn from a basic workflow engine into a powerful, knowledge-enhanced AI agent framework suitable for production use in Rails applications. 