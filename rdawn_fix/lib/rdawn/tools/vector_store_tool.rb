# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Rdawn
  module Tools
    class VectorStoreTool
      def initialize(api_key: nil)
        @api_key = api_key || ENV['OPENAI_API_KEY'] || ENV['RDAWN_LLM_API_KEY']
        raise Rdawn::Errors::ConfigurationError, 'OpenAI API key is required' unless @api_key
      end

      def create_vector_store(name:, file_ids: [], expires_after: nil)
        # Create a vector store with the given name and list of file IDs.
        #
        # Args:
        #   name (String): The name for the vector store
        #   file_ids (Array): List of file IDs (e.g., ["file-xxx"])
        #   expires_after (Hash): Optional expiration settings
        #
        # Returns:
        #   Hash: The vector store response with id and other details
        #
        # Raises:
        #   ConfigurationError: If name is empty or invalid
        #   TaskExecutionError: If the OpenAI API returns an error
        raise Rdawn::Errors::ConfigurationError, 'Vector Store name must be a non-empty string' if name.nil? || name.empty?

        payload = {
          name: name,
          file_ids: file_ids || []
        }

        payload[:expires_after] = expires_after if expires_after

        response = make_api_request(
          endpoint: '/vector_stores',
          method: 'POST',
          payload: payload
        )

        {
          id: response['id'],
          name: response['name'],
          status: response['status'],
          file_counts: response['file_counts'],
          created_at: response['created_at'],
          expires_at: response['expires_at']
        }
      end

      def get_vector_store(vector_store_id)
        # Retrieve information about a vector store.
        #
        # Args:
        #   vector_store_id (String): The ID of the vector store
        #
        # Returns:
        #   Hash: The vector store information
        response = make_api_request(
          endpoint: "/vector_stores/#{vector_store_id}",
          method: 'GET'
        )

        {
          id: response['id'],
          name: response['name'],
          status: response['status'],
          file_counts: response['file_counts'],
          created_at: response['created_at'],
          expires_at: response['expires_at']
        }
      end

      def list_vector_stores(limit: 20, order: 'desc')
        # List all vector stores.
        #
        # Args:
        #   limit (Integer): Maximum number of stores to return
        #   order (String): Sort order ('asc' or 'desc')
        #
        # Returns:
        #   Array: List of vector stores
        response = make_api_request(
          endpoint: "/vector_stores?limit=#{limit}&order=#{order}",
          method: 'GET'
        )

        response['data'].map do |store|
          {
            id: store['id'],
            name: store['name'],
            status: store['status'],
            file_counts: store['file_counts'],
            created_at: store['created_at'],
            expires_at: store['expires_at']
          }
        end
      end

      def delete_vector_store(vector_store_id)
        # Delete a vector store.
        #
        # Args:
        #   vector_store_id (String): The ID of the vector store to delete
        #
        # Returns:
        #   Hash: Deletion status
        response = make_api_request(
          endpoint: "/vector_stores/#{vector_store_id}",
          method: 'DELETE'
        )

        {
          id: response['id'],
          deleted: response['deleted']
        }
      end

      def add_file_to_vector_store(vector_store_id, file_id)
        # Add a file to a vector store.
        #
        # Args:
        #   vector_store_id (String): The ID of the vector store
        #   file_id (String): The ID of the file to add
        #
        # Returns:
        #   Hash: The file association response
        response = make_api_request(
          endpoint: "/vector_stores/#{vector_store_id}/files",
          method: 'POST',
          payload: { file_id: file_id }
        )

        {
          id: response['id'],
          vector_store_id: response['vector_store_id'],
          status: response['status'],
          created_at: response['created_at']
        }
      end

      def list_vector_store_files(vector_store_id, limit: 20, order: 'desc')
        # List files in a vector store.
        #
        # Args:
        #   vector_store_id (String): The ID of the vector store
        #   limit (Integer): Maximum number of files to return
        #   order (String): Sort order ('asc' or 'desc')
        #
        # Returns:
        #   Array: List of files in the vector store
        response = make_api_request(
          endpoint: "/vector_stores/#{vector_store_id}/files?limit=#{limit}&order=#{order}",
          method: 'GET'
        )

        response['data'].map do |file|
          {
            id: file['id'],
            vector_store_id: file['vector_store_id'],
            status: file['status'],
            created_at: file['created_at']
          }
        end
      end

      def remove_file_from_vector_store(vector_store_id, file_id)
        # Remove a file from a vector store.
        #
        # Args:
        #   vector_store_id (String): The ID of the vector store
        #   file_id (String): The ID of the file to remove
        #
        # Returns:
        #   Hash: Removal status
        response = make_api_request(
          endpoint: "/vector_stores/#{vector_store_id}/files/#{file_id}",
          method: 'DELETE'
        )

        {
          id: response['id'],
          deleted: response['deleted']
        }
      end

      private

      def make_api_request(endpoint:, method: 'GET', payload: nil)
        uri = URI("https://api.openai.com/v1#{endpoint}")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = case method.upcase
                  when 'GET'
                    Net::HTTP::Get.new(uri)
                  when 'POST'
                    Net::HTTP::Post.new(uri)
                  when 'DELETE'
                    Net::HTTP::Delete.new(uri)
                  else
                    raise Rdawn::Errors::ConfigurationError, "Unsupported HTTP method: #{method}"
                  end

        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request['OpenAI-Beta'] = 'assistants=v2'

        if payload
          request.body = JSON.generate(payload)
        end

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