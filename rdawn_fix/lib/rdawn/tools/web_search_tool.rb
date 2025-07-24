# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Rdawn
  module Tools
    class WebSearchTool
      def initialize(api_key: nil)
        @api_key = api_key || ENV['OPENAI_API_KEY'] || ENV['RDAWN_LLM_API_KEY']
        raise Rdawn::Errors::ConfigurationError, 'OpenAI API key is required' unless @api_key
      end

      def search(query:, context_size: 'medium', user_location: nil, model: 'gpt-4o')
        # Perform a web search using the OpenAI API.
        #
        # Args:
        #   query (String): The search query
        #   context_size (String): Size of search context ('small', 'medium', 'large')
        #   user_location (String): Optional user location for localized results
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        #
        # Raises:
        #   ConfigurationError: If query is invalid
        #   TaskExecutionError: If the OpenAI API returns an error
        raise Rdawn::Errors::ConfigurationError, 'Query is required' if query.nil? || query.empty?
        
        # Validate context size
        valid_sizes = ['low', 'medium', 'high']
        unless valid_sizes.include?(context_size)
          raise Rdawn::Errors::ConfigurationError, "Invalid context size: #{context_size}. Must be one of: #{valid_sizes.join(', ')}"
        end

        # Configure the web search tool
        tools_config = [{
          type: 'web_search_preview',
          search_context_size: context_size
        }]

        # Add user location if provided
        if user_location
          tools_config[0][:user_location] = user_location
        end

        # Build the request
        payload = {
          model: model,
          tools: tools_config,
          input: query
        }

        response = make_responses_request(payload)

        # Extract content from OpenAI Responses API structure
        content = extract_content_from_response(response)

        {
          query: query,
          content: content,
          context_size: context_size,
          user_location: user_location,
          model: model,
          usage: response['usage']
        }
      end

      def search_with_context(query:, context:, context_size: 'medium', model: 'gpt-4o')
        # Perform a web search with additional context.
        #
        # Args:
        #   query (String): The search query
        #   context (String): Additional context to help with the search
        #   context_size (String): Size of search context
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        enhanced_query = "Context: #{context}\n\nSearch for: #{query}"
        
        search(
          query: enhanced_query,
          context_size: context_size,
          model: model
        )
      end

      def search_news(query:, context_size: 'medium', model: 'gpt-4o')
        # Search for news articles related to the query.
        #
        # Args:
        #   query (String): The search query
        #   context_size (String): Size of search context
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        news_query = "Latest news about: #{query}"
        
        search(
          query: news_query,
          context_size: context_size,
          model: model
        )
      end

      def search_recent(query:, timeframe: 'today', context_size: 'medium', model: 'gpt-4o')
        # Search for recent information about a topic.
        #
        # Args:
        #   query (String): The search query
        #   timeframe (String): Time constraint ('today', 'this week', 'this month')
        #   context_size (String): Size of search context
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        time_query = "Recent information from #{timeframe} about: #{query}"
        
        search(
          query: time_query,
          context_size: context_size,
          model: model
        )
      end

      def search_with_filters(query:, filters: {}, context_size: 'medium', model: 'gpt-4o')
        # Perform a web search with additional filters.
        #
        # Args:
        #   query (String): The search query
        #   filters (Hash): Additional filters like site, filetype, etc.
        #   context_size (String): Size of search context
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Hash: The search results with content and metadata
        enhanced_query = query
        
        # Add site filter
        if filters[:site]
          enhanced_query += " site:#{filters[:site]}"
        end
        
        # Add filetype filter
        if filters[:filetype]
          enhanced_query += " filetype:#{filters[:filetype]}"
        end
        
        # Add time filter
        if filters[:time]
          enhanced_query += " #{filters[:time]}"
        end
        
        # Add custom filters
        if filters[:custom]
          enhanced_query += " #{filters[:custom]}"
        end
        
        search(
          query: enhanced_query,
          context_size: context_size,
          model: model
        )
      end

      def multi_search(queries:, context_size: 'medium', model: 'gpt-4o')
        # Perform multiple web searches and combine results.
        #
        # Args:
        #   queries (Array): Array of search queries
        #   context_size (String): Size of search context
        #   model (String): The model to use for the search
        #
        # Returns:
        #   Array: Array of search results
        raise Rdawn::Errors::ConfigurationError, 'Queries array is required' if queries.nil? || queries.empty?
        
        results = []
        
        queries.each_with_index do |query, index|
          begin
            result = search(
              query: query,
              context_size: context_size,
              model: model
            )
            results << result.merge(query_index: index)
          rescue => e
            results << {
              query: query,
              query_index: index,
              error: e.message,
              content: nil
            }
          end
        end
        
        results
      end

      private

      def extract_content_from_response(response)
        # Extract content from OpenAI Responses API response structure
        # The response has an 'output' array with different items
        # We need to find the 'message' item and get its content text
        
        return nil unless response && response['output']
        
        # Find the message item in the output array
        message_item = response['output'].find { |item| item['type'] == 'message' }
        return nil unless message_item && message_item['content']
        
        # Extract the text from the first content item
        text_content = message_item['content'].find { |content| content['type'] == 'output_text' }
        return nil unless text_content
        
        text_content['text']
      end

      def make_responses_request(payload)
        uri = URI('https://api.openai.com/v1/responses')
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 60  # Longer timeout for web search requests

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