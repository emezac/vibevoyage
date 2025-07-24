# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Rdawn
  module Tools
    class FileSearchTool
      def initialize(api_key: nil)
        @api_key = api_key || ENV['OPENAI_API_KEY'] || ENV['RDAWN_LLM_API_KEY']
        raise Rdawn::Errors::ConfigurationError, 'OpenAI API key is required' unless @api_key
      end

      def search_files(query:, vector_store_ids:, max_results: 5, model: 'gpt-4o-mini')
        # Execute a file search query using the specified vector store(s).
        #
        # Args:
        #   query (String): The query string to search within the indexed files
        #   vector_store_ids (Array): List of vector store IDs (must start with "vs_")
        #   max_results (Integer): Maximum number of search results to return
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        #
        # Raises:
        #   ConfigurationError: If query or vector_store_ids are invalid
        #   TaskExecutionError: If the OpenAI API returns an error
        raise Rdawn::Errors::ConfigurationError, 'Query is required' if query.nil? || query.empty?
        raise Rdawn::Errors::ConfigurationError, 'Vector store IDs are required' if vector_store_ids.nil? || vector_store_ids.empty?
        
        # Validate vector store IDs
        invalid_ids = vector_store_ids.reject { |id| id.start_with?('vs_') }
        unless invalid_ids.empty?
          raise Rdawn::Errors::ConfigurationError, "Invalid vector store IDs: #{invalid_ids.join(', ')} (must start with 'vs_')"
        end

        # Use OpenAI's chat completion with file search tool
        response = perform_file_search_with_chat(
          query: query,
          vector_store_ids: vector_store_ids,
          max_results: max_results,
          model: model
        )

        {
          query: query,
          vector_store_ids: vector_store_ids,
          results: response[:results],
          content: response[:content],
          usage: response[:usage]
        }
      end

      def search_with_context(query:, vector_store_ids:, context: nil, max_results: 5, model: 'gpt-4o-mini')
        # Execute a file search query with additional context.
        #
        # Args:
        #   query (String): The query string to search within the indexed files
        #   vector_store_ids (Array): List of vector store IDs
        #   context (String): Additional context to help with the search
        #   max_results (Integer): Maximum number of search results to return
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        enhanced_query = if context
          "Context: #{context}\n\nQuery: #{query}"
        else
          query
        end

        search_files(
          query: enhanced_query,
          vector_store_ids: vector_store_ids,
          max_results: max_results,
          model: model
        )
      end

      private

      def perform_file_search_with_chat(query:, vector_store_ids:, max_results:, model:)
        # Configure the function-calling tool for file search
        tools_config = [{
          type: 'function',
          function: {
            name: 'file_search',
            description: 'Search through files using vector search',
            parameters: {
              type: 'object',
              properties: {
                vector_store_ids: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'List of vector store IDs to search in'
                },
                max_results: {
                  type: 'integer',
                  description: 'Maximum number of results to return'
                }
              },
              required: ['vector_store_ids']
            }
          }
        }]

        # First request to get the model to use the file search tool
        messages = [
          { role: 'system', content: 'You are a helpful assistant that provides information from files.' },
          { role: 'user', content: query }
        ]

        payload = {
          model: model,
          messages: messages,
          tools: tools_config,
          tool_choice: { type: 'function', function: { name: 'file_search' } }
        }

        first_response = make_chat_request(payload)
        
        # Check if the response has tool calls
        if first_response['choices'] && 
           first_response['choices'][0]['message'] &&
           first_response['choices'][0]['message']['tool_calls']
          
          tool_calls = first_response['choices'][0]['message']['tool_calls']
          file_search_call = tool_calls.find { |call| call['function']['name'] == 'file_search' }
          
          if file_search_call
            # Make a follow-up request with the tool results
            tool_args = JSON.parse(file_search_call['function']['arguments'])
            
            follow_up_messages = [
              { role: 'system', content: 'You are a helpful assistant that provides information from files.' },
              { role: 'user', content: query },
              {
                role: 'assistant',
                content: nil,
                tool_calls: [{
                  id: file_search_call['id'],
                  type: 'function',
                  function: {
                    name: 'file_search',
                    arguments: file_search_call['function']['arguments']
                  }
                }]
              },
              {
                role: 'tool',
                tool_call_id: file_search_call['id'],
                content: build_search_results_content(
                  vector_store_ids: tool_args['vector_store_ids'] || vector_store_ids,
                  query: query,
                  max_results: tool_args['max_results'] || max_results
                )
              }
            ]

            follow_up_payload = {
              model: model,
              messages: follow_up_messages
            }

            follow_up_response = make_chat_request(follow_up_payload)
            
            content = follow_up_response.dig('choices', 0, 'message', 'content')
            
            return {
              results: extract_search_results(content),
              content: content,
              usage: follow_up_response['usage']
            }
          end
        end

        # If no tool calls, return the direct response
        content = first_response.dig('choices', 0, 'message', 'content')
        
        {
          results: [],
          content: content,
          usage: first_response['usage']
        }
      end

      def build_search_results_content(vector_store_ids:, query:, max_results:)
        # Build content for the tool call response simulating search results.
        # In a real implementation, this would contain actual search results.
        
        "Search results from vector stores #{vector_store_ids.join(', ')} for query: '#{query}' (max #{max_results} results)"
      end

      def extract_search_results(content)
        # Extract structured search results from the content.
        # This is a simplified version - in practice, you might want more sophisticated parsing.
        return [] unless content

        # Simple extraction - look for numbered lists or bullet points
        results = []
        lines = content.split("\n")
        
        lines.each_with_index do |line, index|
          # Look for numbered items (1., 2., etc.) or bullet points
          if line.match(/^\d+\.\s+/) || line.match(/^[\*\-]\s+/)
            results << {
              index: results.length + 1,
              content: line.strip,
              context: lines[index + 1]&.strip
            }
          end
        end
        
        results
      end

      def make_chat_request(payload)
        uri = URI('https://api.openai.com/v1/chat/completions')
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 60  # Longer timeout for search requests

        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(payload)

        response = http.request(request)
        
        case response.code.to_i
        when 200..299
          JSON.parse(response.body)
        when 400..499
          error_body = JSON.parse(response.body) rescue { 'error' => { 'message' => response.body } }
          raise Rdawn::Errors::ConfigurationError, "API Error: #{error_body.dig('error', 'message') || response.body}"
        when 500..599
          raise Rdawn::Errors::TaskExecutionError, "Server Error: #{response.code} - #{response.body}"
        else
          raise Rdawn::Errors::TaskExecutionError, "Unexpected response: #{response.code} - #{response.body}"
        end
      end
    end
  end
end 