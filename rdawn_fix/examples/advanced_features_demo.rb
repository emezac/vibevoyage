#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced Features Demo for rdawn
# This demonstrates RAG (Retrieval-Augmented Generation) and Web Search capabilities

puts "🚀 Rdawn Advanced Features Demo"
puts "=" * 50

# Load rdawn
require 'rdawn'

# Example 1: RAG Workflow with Vector Stores
puts "\n1. RAG Workflow with Vector Stores"
puts "-" * 30

# Register advanced tools
api_key = ENV['OPENAI_API_KEY'] || 'your_api_key_here'
puts "Registering advanced tools..."
Rdawn::Tools.register_advanced_tools(api_key: api_key)

# Create a workflow that uses RAG
rag_workflow_data = {
  workflow_id: 'rag_demo',
  name: 'RAG Demonstration Workflow',
  tasks: {
    'upload_files' => {
      type: 'tool',
      name: 'Upload Files to Vector Store',
      tool_name: 'file_upload',
      input_data: {
        file_path: '${file_path}',
        purpose: 'assistants'
      },
      next_task_id_on_success: 'create_vector_store'
    },
    'create_vector_store' => {
      type: 'tool',
      name: 'Create Vector Store',
      tool_name: 'vector_store_create',
      input_data: {
        name: 'Demo Knowledge Base',
        file_ids: ['${upload_files.id}']
      },
      next_task_id_on_success: 'search_files'
    },
    'search_files' => {
      type: 'tool',
      name: 'Search Files',
      tool_name: 'file_search',
      input_data: {
        query: '${search_query}',
        vector_store_ids: ['${create_vector_store.id}'],
        max_results: 5
      },
      next_task_id_on_success: 'generate_response'
    },
    'generate_response' => {
      type: 'llm',
      name: 'Generate Response with RAG',
      input_data: {
        prompt: 'Based on the search results: ${search_files.content}\n\nAnswer the question: ${search_query}',
        model_params: { temperature: 0.7 }
      }
    }
  }
}

puts "RAG Workflow Structure:"
puts "- #{rag_workflow_data[:tasks].keys.count} tasks"
puts "- Flow: #{rag_workflow_data[:tasks].keys.join(' → ')}"

# Example 2: Web Search Workflow
puts "\n2. Web Search Workflow"
puts "-" * 30

web_search_workflow_data = {
  workflow_id: 'web_search_demo',
  name: 'Web Search Demonstration',
  tasks: {
    'search_web' => {
      type: 'tool',
      name: 'Search Web',
      tool_name: 'web_search',
      input_data: {
        query: '${search_query}',
        context_size: 'medium'
      },
      next_task_id_on_success: 'search_news'
    },
    'search_news' => {
      type: 'tool',
      name: 'Search News',
      tool_name: 'web_search_news',
      input_data: {
        query: '${search_query}',
        context_size: 'large'
      },
      next_task_id_on_success: 'combine_results'
    },
    'combine_results' => {
      type: 'llm',
      name: 'Combine Web and News Results',
      input_data: {
        prompt: 'Web search results: ${search_web.content}\n\nNews results: ${search_news.content}\n\nProvide a comprehensive summary about: ${search_query}',
        model_params: { temperature: 0.5, max_tokens: 1500 }
      }
    }
  }
}

puts "Web Search Workflow Structure:"
puts "- #{web_search_workflow_data[:tasks].keys.count} tasks"
puts "- Flow: #{web_search_workflow_data[:tasks].keys.join(' → ')}"

# Example 3: Enhanced LLM Interface with RAG
puts "\n3. Enhanced LLM Interface with RAG"
puts "-" * 30

llm_with_rag_example = {
  llm_config: {
    api_key: api_key,
    model: 'gpt-4o-mini',
    use_file_search: true,
    vector_store_ids: ['vs_example_id'],
    max_file_search_results: 10
  },
  usage: "llm_interface = Rdawn::LLMInterface.new(llm_config)"
}

puts "LLM with RAG Configuration:"
puts "- File search enabled: #{llm_with_rag_example[:llm_config][:use_file_search]}"
puts "- Vector stores: #{llm_with_rag_example[:llm_config][:vector_store_ids]}"
puts "- Max results: #{llm_with_rag_example[:llm_config][:max_file_search_results]}"

# Example 4: Enhanced LLM Interface with Web Search
puts "\n4. Enhanced LLM Interface with Web Search"
puts "-" * 30

llm_with_web_search_example = {
  llm_config: {
    api_key: api_key,
    model: 'gpt-4o',
    use_web_search: true,
    web_search_context_size: 'large'
  },
  usage: "llm_interface = Rdawn::LLMInterface.new(llm_config)"
}

puts "LLM with Web Search Configuration:"
puts "- Web search enabled: #{llm_with_web_search_example[:llm_config][:use_web_search]}"
puts "- Context size: #{llm_with_web_search_example[:llm_config][:web_search_context_size]}"

# Example 5: Complete RAG Setup Code
puts "\n5. Complete RAG Setup Example"
puts "-" * 30

rag_setup_code = <<~RUBY
  # Complete RAG workflow setup
  require 'rdawn'
  
  # Register advanced tools
  Rdawn::Tools.register_advanced_tools(api_key: ENV['OPENAI_API_KEY'])
  
  # Create a complete RAG workflow
  rag_workflow = Rdawn::Tools.create_rag_workflow(
    name: 'Company Knowledge Base',
    file_paths: [
      'docs/company_handbook.pdf',
      'docs/technical_specs.md',
      'docs/faq.txt'
    ],
    api_key: ENV['OPENAI_API_KEY']
  )
  
  # Use the RAG workflow
  puts "Vector Store ID: \#{rag_workflow[:vector_store_id]}"
  puts "Ready to search: \#{rag_workflow[:ready]}"
  
  # Search the knowledge base
  results = Rdawn::Tools.multi_store_search(
    query: 'What is our company policy on remote work?',
    vector_store_ids: [rag_workflow[:vector_store_id]],
    max_results: 5
  )
  
  puts "Search results: \#{results[:content]}"
RUBY

puts rag_setup_code

# Example 6: Rails Integration with Advanced Features
puts "\n6. Rails Integration with Advanced Features"
puts "-" * 30

rails_integration_code = <<~RUBY
  # In your Rails controller
  class KnowledgeBaseController < ApplicationController
    def search
      # Create workflow with RAG
      workflow_data = {
        workflow_id: "kb_search_\#{current_user.id}",
        name: 'Knowledge Base Search',
        tasks: {
          'search_knowledge' => {
            type: 'tool',
            name: 'Search Knowledge Base',
            tool_name: 'file_search',
            input_data: {
              query: params[:query],
              vector_store_ids: [company_vector_store_id],
              max_results: 10
            },
            next_task_id_on_success: 'web_search_fallback'
          },
          'web_search_fallback' => {
            type: 'tool',
            name: 'Web Search Fallback',
            tool_name: 'web_search',
            input_data: {
              query: params[:query],
              context_size: 'large'
            },
            condition: { 'eq' => ['\${search_knowledge.results.length}', 0] },
            next_task_id_on_success: 'generate_answer'
          },
          'generate_answer' => {
            type: 'llm',
            name: 'Generate Final Answer',
            input_data: {
              prompt: build_answer_prompt(params[:query]),
              model_params: { temperature: 0.3 }
            }
          }
        }
      }
      
      # Execute in background
      Rdawn::Rails::WorkflowJob.run_workflow_later(
        workflow_data: workflow_data,
        llm_config: { api_key: ENV['OPENAI_API_KEY'] },
        initial_input: { query: params[:query] },
        user_context: { current_user_id: current_user.id }
      )
      
      render json: { message: 'Search started', status: 'processing' }
    end
    
    private
    
    def company_vector_store_id
      Rails.cache.fetch('company_vector_store_id', expires_in: 1.day) do
        # Get or create company vector store
        'vs_company_knowledge_base'
      end
    end
    
    def build_answer_prompt(query)
      context = []
      context << "Internal search results: \${search_knowledge.content}" if '\${search_knowledge.results.length}' > 0
      context << "Web search results: \${web_search_fallback.content}" if '\${web_search_fallback.content}'.present?
      
      "Context: \#{context.join('\n\n')}\n\nQuestion: \#{query}\n\nProvide a comprehensive answer based on the available information."
    end
  end
RUBY

puts rails_integration_code

# Example 7: Tool Registry Usage
puts "\n7. Tool Registry Usage"
puts "-" * 30

tool_registry_code = <<~RUBY
  # Register advanced tools
  Rdawn::Tools.register_advanced_tools(api_key: ENV['OPENAI_API_KEY'])
  
  # Available tools after registration:
  puts "Registered tools:"
  puts "- vector_store_create, vector_store_get, vector_store_list, vector_store_delete"
  puts "- file_upload, file_upload_from_url, file_get_info, file_list, file_delete"
  puts "- file_search, file_search_with_context"
  puts "- web_search, web_search_news, web_search_recent, web_search_with_filters"
  
  # Use tools directly
  vector_store = Rdawn::ToolRegistry.execute('vector_store_create', {
    name: 'My Knowledge Base',
    file_ids: ['file-123', 'file-456']
  })
  
  search_results = Rdawn::ToolRegistry.execute('file_search', {
    query: 'What is machine learning?',
    vector_store_ids: [vector_store[:id]],
    max_results: 5
  })
  
  web_results = Rdawn::ToolRegistry.execute('web_search', {
    query: 'Latest AI developments',
    context_size: 'large'
  })
RUBY

puts tool_registry_code

puts "\n🎉 Advanced Features Demo Complete!"
puts "=" * 50
puts "This demonstrates how rdawn integrates RAG and web search capabilities"
puts "for building powerful, knowledge-enhanced AI agent workflows."
puts "\nKey Features Demonstrated:"
puts "✅ Vector Store Management (create, upload, search)"
puts "✅ File Upload and Processing"
puts "✅ Semantic File Search (RAG)"
puts "✅ Web Search Integration"
puts "✅ Enhanced LLM Interface"
puts "✅ Rails Integration Patterns"
puts "✅ Tool Registry System" 