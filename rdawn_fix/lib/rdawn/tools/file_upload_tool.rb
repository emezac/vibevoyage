# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'mime/types'

module Rdawn
  module Tools
    class FileUploadTool
      def initialize(api_key: nil)
        @api_key = api_key || ENV['OPENAI_API_KEY'] || ENV['RDAWN_LLM_API_KEY']
        raise Rdawn::Errors::ConfigurationError, 'OpenAI API key is required' unless @api_key
      end

      def upload_file(file_path:, purpose: 'assistants')
        # Upload a file using the OpenAI API and return the file ID.
        #
        # Args:
        #   file_path (String): Path to the file to upload
        #   purpose (String): The purpose for the file upload ('assistants', 'fine-tune', etc.)
        #
        # Returns:
        #   Hash: The uploaded file information with id and other details
        #
        # Raises:
        #   ConfigurationError: If file_path is invalid or file doesn't exist
        #   TaskExecutionError: If the OpenAI API returns an error
        raise Rdawn::Errors::ConfigurationError, 'File path is required' if file_path.nil? || file_path.empty?
        raise Rdawn::Errors::ConfigurationError, "File not found: #{file_path}" unless File.exist?(file_path)

        # Check file size (OpenAI has limits)
        file_size = File.size(file_path)
        max_size = 512 * 1024 * 1024  # 512MB limit for assistants
        
        if file_size > max_size
          raise Rdawn::Errors::ConfigurationError, "File too large: #{file_size} bytes (max: #{max_size} bytes)"
        end

        # Get file info
        filename = File.basename(file_path)
        content_type = get_content_type(file_path)

        # Create multipart form data
        boundary = "----RdawnFormBoundary#{Time.now.to_i}"
        
        form_data = build_multipart_form_data(
          file_path: file_path,
          filename: filename,
          content_type: content_type,
          purpose: purpose,
          boundary: boundary
        )

        response = make_upload_request(form_data, boundary)

        {
          id: response['id'],
          filename: response['filename'],
          bytes: response['bytes'],
          created_at: response['created_at'],
          purpose: response['purpose'],
          status: response['status']
        }
      end

      def upload_file_from_url(url:, purpose: 'assistants')
        # Upload a file from a URL using the OpenAI API.
        #
        # Args:
        #   url (String): URL of the file to upload
        #   purpose (String): The purpose for the file upload
        #
        # Returns:
        #   Hash: The uploaded file information
        #
        # Raises:
        #   ConfigurationError: If URL is invalid
        #   TaskExecutionError: If download or upload fails
        raise Rdawn::Errors::ConfigurationError, 'URL is required' if url.nil? || url.empty?

        # Download file to temporary location
        temp_file = download_file_from_url(url)
        
        begin
          # Upload the downloaded file
          upload_file(file_path: temp_file, purpose: purpose)
        ensure
          # Clean up temporary file
          File.delete(temp_file) if File.exist?(temp_file)
        end
      end

      def get_file_info(file_id)
        # Retrieve information about an uploaded file.
        #
        # Args:
        #   file_id (String): The ID of the file
        #
        # Returns:
        #   Hash: File information
        response = make_api_request(
          endpoint: "/files/#{file_id}",
          method: 'GET'
        )

        {
          id: response['id'],
          filename: response['filename'],
          bytes: response['bytes'],
          created_at: response['created_at'],
          purpose: response['purpose'],
          status: response['status']
        }
      end

      def list_files(purpose: nil, limit: 20)
        # List uploaded files.
        #
        # Args:
        #   purpose (String): Filter by purpose (optional)
        #   limit (Integer): Maximum number of files to return
        #
        # Returns:
        #   Array: List of file information
        endpoint = "/files?limit=#{limit}"
        endpoint += "&purpose=#{purpose}" if purpose

        response = make_api_request(
          endpoint: endpoint,
          method: 'GET'
        )

        response['data'].map do |file|
          {
            id: file['id'],
            filename: file['filename'],
            bytes: file['bytes'],
            created_at: file['created_at'],
            purpose: file['purpose'],
            status: file['status']
          }
        end
      end

      def delete_file(file_id)
        # Delete an uploaded file.
        #
        # Args:
        #   file_id (String): The ID of the file to delete
        #
        # Returns:
        #   Hash: Deletion status
        response = make_api_request(
          endpoint: "/files/#{file_id}",
          method: 'DELETE'
        )

        {
          id: response['id'],
          deleted: response['deleted']
        }
      end

      def get_file_content(file_id)
        # Retrieve the content of an uploaded file.
        #
        # Args:
        #   file_id (String): The ID of the file
        #
        # Returns:
        #   String: File content
        uri = URI("https://api.openai.com/v1/files/#{file_id}/content")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"

        response = http.request(request)
        
        case response.code.to_i
        when 200..299
          response.body
        when 400..499
          error_body = JSON.parse(response.body) rescue { 'error' => { 'message' => response.body } }
          raise Rdawn::Errors::ConfigurationError, "API Error: #{error_body.dig('error', 'message') || response.body}"
        when 500..599
          raise Rdawn::Errors::TaskExecutionError, "Server Error: #{response.code} - #{response.body}"
        else
          raise Rdawn::Errors::TaskExecutionError, "Unexpected response: #{response.code} - #{response.body}"
        end
      end

      private

      def get_content_type(file_path)
        mime_types = MIME::Types.type_for(file_path)
        mime_types.first&.content_type || 'application/octet-stream'
      end

      def build_multipart_form_data(file_path:, filename:, content_type:, purpose:, boundary:)
        file_content = File.binread(file_path)
        
        form_data = String.new
        form_data << "--#{boundary}\r\n"
        form_data << "Content-Disposition: form-data; name=\"purpose\"\r\n\r\n"
        form_data << "#{purpose}\r\n"
        form_data << "--#{boundary}\r\n"
        form_data << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
        form_data << "Content-Type: #{content_type}\r\n\r\n"
        form_data << file_content
        form_data << "\r\n--#{boundary}--\r\n"
        
        form_data
      end

      def make_upload_request(form_data, boundary)
        uri = URI('https://api.openai.com/v1/files')
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        request.body = form_data

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

      def download_file_from_url(url)
        uri = URI(url)
        filename = File.basename(uri.path)
        filename = "downloaded_file_#{Time.now.to_i}" if filename.empty?
        
        temp_file = "/tmp/rdawn_#{filename}"
        
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new(uri)
          
          http.request(request) do |response|
            case response.code.to_i
            when 200..299
              File.open(temp_file, 'wb') do |file|
                response.read_body do |chunk|
                  file.write(chunk)
                end
              end
            else
              raise Rdawn::Errors::TaskExecutionError, "Failed to download file: #{response.code} - #{response.message}"
            end
          end
        end
        
        temp_file
      end

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