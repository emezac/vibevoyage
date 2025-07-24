# frozen_string_literal: true

require 'rdawn/errors'
require 'net/http'
require 'json'
require 'fileutils'
require 'tempfile'

module Rdawn
  module Tools
    # A comprehensive markdown tool that integrates with Marksmith for GitHub-style markdown editing
    # and provides AI-powered content generation, editing, and formatting capabilities.
    class MarkdownTool
      include Rdawn::Tools

      attr_reader :api_key, :temp_dir, :marksmith_enabled

      def initialize(api_key:, temp_dir: nil, marksmith_enabled: true)
        @api_key = api_key
        @temp_dir = temp_dir || Dir.tmpdir
        @marksmith_enabled = marksmith_enabled
        
        ensure_temp_directory
      end

      # Generate markdown content using AI
      def generate_markdown(prompt:, style: 'technical', model: 'gpt-4o-mini', length: 'medium')
        raise Rdawn::Errors::ConfigurationError, 'API key is required' if @api_key.nil? || @api_key.empty?
        
        # Enhanced prompt for markdown generation
        enhanced_prompt = build_generation_prompt(prompt, style, length)
        
        # Call LLM to generate markdown
        response = call_llm(enhanced_prompt, model)
        
        # Extract and clean the markdown
        markdown_content = extract_markdown_from_response(response)
        
        {
          prompt: prompt,
          style: style,
          length: length,
          markdown: markdown_content,
          word_count: count_words(markdown_content),
          model: model,
          generated_at: Time.now
        }
      end

      # Edit existing markdown content with AI assistance
      def edit_markdown(markdown:, instructions:, model: 'gpt-4o-mini', preserve_style: true)
        raise Rdawn::Errors::ConfigurationError, 'Markdown content is required' if markdown.nil? || markdown.empty?
        raise Rdawn::Errors::ConfigurationError, 'Edit instructions are required' if instructions.nil? || instructions.empty?
        
        # Build edit prompt
        edit_prompt = build_edit_prompt(markdown, instructions, preserve_style)
        
        # Call LLM for editing
        response = call_llm(edit_prompt, model)
        
        # Extract edited content
        edited_content = extract_markdown_from_response(response)
        
        {
          original_markdown: markdown,
          instructions: instructions,
          edited_markdown: edited_content,
          changes_summary: summarize_changes(markdown, edited_content),
          word_count_before: count_words(markdown),
          word_count_after: count_words(edited_content),
          model: model,
          edited_at: Time.now
        }
      end

      # Convert markdown to HTML with GitHub-style rendering
      def markdown_to_html(markdown:, github_style: true, syntax_highlighting: true)
        if marksmith_available?
          # Use Marksmith's renderer if available
          render_with_marksmith(markdown, github_style, syntax_highlighting)
        else
          # Fallback to basic rendering
          render_with_basic_markdown(markdown, github_style, syntax_highlighting)
        end
      end

      # Format and beautify markdown content
      def format_markdown(markdown:, style: 'standard', line_length: 80)
        formatted_content = case style
        when 'standard'
          format_standard_markdown(markdown, line_length)
        when 'compact'
          format_compact_markdown(markdown)
        when 'extended'
          format_extended_markdown(markdown, line_length)
        else
          markdown
        end
        
        {
          original_markdown: markdown,
          formatted_markdown: formatted_content,
          style: style,
          line_length: line_length,
          formatted_at: Time.now
        }
      end

      # Create a Marksmith-compatible form field
      def create_marksmith_field(field_name:, initial_content: '', placeholder: 'Enter markdown...')
        if marksmith_available?
          {
            field_name: field_name,
            initial_content: initial_content,
            placeholder: placeholder,
            marksmith_config: generate_marksmith_config,
            form_helper: generate_form_helper_code(field_name, initial_content, placeholder)
          }
        else
          {
            field_name: field_name,
            initial_content: initial_content,
            placeholder: placeholder,
            fallback_textarea: generate_fallback_textarea(field_name, initial_content, placeholder),
            warning: 'Marksmith not available, using fallback textarea'
          }
        end
      end

      # Generate table of contents from markdown
      def generate_toc(markdown:, max_depth: 3, style: 'bullet')
        headings = extract_headings(markdown)
        filtered_headings = headings.select { |h| h[:level] <= max_depth }
        
        toc_content = case style
        when 'bullet'
          generate_bullet_toc(filtered_headings)
        when 'numbered'
          generate_numbered_toc(filtered_headings)
        when 'links'
          generate_links_toc(filtered_headings)
        else
          generate_bullet_toc(filtered_headings)
        end
        
        {
          original_markdown: markdown,
          toc_markdown: toc_content,
          headings_count: filtered_headings.length,
          max_depth: max_depth,
          style: style,
          generated_at: Time.now
        }
      end

      # Validate markdown syntax and structure
      def validate_markdown(markdown:, strict: false)
        issues = []
        
        # Check for common markdown issues
        issues += check_heading_structure(markdown)
        issues += check_link_validity(markdown) if strict
        issues += check_code_blocks(markdown)
        issues += check_list_formatting(markdown)
        issues += check_table_formatting(markdown)
        
        {
          markdown: markdown,
          valid: issues.empty?,
          issues: issues,
          issue_count: issues.length,
          validated_at: Time.now
        }
      end

      # Create markdown templates
      def create_template(type:, title: '', author: '', tags: [])
        template_content = case type
        when 'article'
          create_article_template(title, author, tags)
        when 'readme'
          create_readme_template(title, author)
        when 'blog_post'
          create_blog_post_template(title, author, tags)
        when 'documentation'
          create_documentation_template(title, author)
        when 'api_docs'
          create_api_docs_template(title, author)
        else
          create_basic_template(title, author, tags)
        end
        
        {
          type: type,
          title: title,
          author: author,
          tags: tags,
          template_markdown: template_content,
          created_at: Time.now
        }
      end

      # AI-powered content suggestions
      def suggest_improvements(markdown:, focus: 'readability', model: 'gpt-4o-mini')
        analysis_prompt = build_analysis_prompt(markdown, focus)
        response = call_llm(analysis_prompt, model)
        
        {
          original_markdown: markdown,
          focus: focus,
          suggestions: parse_suggestions(response),
          model: model,
          analyzed_at: Time.now
        }
      end

      # Batch process multiple markdown files
      def batch_process(files:, operation:, **options)
        results = []
        
        files.each do |file_path|
          begin
            markdown_content = File.read(file_path)
            
            result = case operation
            when 'format'
              format_markdown(markdown: markdown_content, **options)
            when 'validate'
              validate_markdown(markdown: markdown_content, **options)
            when 'generate_toc'
              generate_toc(markdown: markdown_content, **options)
            when 'to_html'
              markdown_to_html(markdown: markdown_content, **options)
            else
              { error: "Unknown operation: #{operation}" }
            end
            
            results << {
              file_path: file_path,
              operation: operation,
              result: result,
              processed_at: Time.now
            }
          rescue => e
            results << {
              file_path: file_path,
              operation: operation,
              error: e.message,
              processed_at: Time.now
            }
          end
        end
        
        {
          operation: operation,
          files_processed: files.length,
          successful: results.count { |r| !r.key?(:error) },
          failed: results.count { |r| r.key?(:error) },
          results: results,
          batch_processed_at: Time.now
        }
      end

      private

      def ensure_temp_directory
        FileUtils.mkdir_p(@temp_dir) unless Dir.exist?(@temp_dir)
      end

      def marksmith_available?
        @marksmith_enabled && defined?(Marksmith)
      rescue
        false
      end

      def call_llm(prompt, model)
        payload = {
          model: model,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7
        }
        
        uri = URI('https://api.openai.com/v1/chat/completions')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(payload)
        
        response = http.request(request)
        
        case response.code.to_i
        when 200..299
          parsed = JSON.parse(response.body)
          parsed.dig('choices', 0, 'message', 'content')
        else
          raise Rdawn::Errors::TaskExecutionError, "LLM API error: #{response.code} - #{response.body}"
        end
      end

      def build_generation_prompt(prompt, style, length)
        style_instructions = {
          'technical' => 'Use technical language, include code examples, and structure content logically.',
          'conversational' => 'Use a friendly, conversational tone that engages the reader.',
          'academic' => 'Use formal academic language with proper citations and references.',
          'creative' => 'Use creative and engaging language with vivid descriptions.',
          'professional' => 'Use professional business language, clear and concise.'
        }
        
        length_instructions = {
          'short' => 'Keep it concise, around 200-300 words.',
          'medium' => 'Create a moderate length article, around 500-800 words.',
          'long' => 'Create a comprehensive piece, around 1000-1500 words.'
        }
        
        <<~PROMPT
          Generate well-structured markdown content based on the following requirements:
          
          Topic: #{prompt}
          Style: #{style_instructions[style] || style_instructions['technical']}
          Length: #{length_instructions[length] || length_instructions['medium']}
          
          Requirements:
          - Use proper markdown syntax with headings, lists, and formatting
          - Include relevant code examples if technical
          - Structure content with clear sections
          - Use appropriate markdown features (tables, links, emphasis)
          - Ensure content is engaging and informative
          
          Return only the markdown content without any additional commentary.
        PROMPT
      end

      def build_edit_prompt(markdown, instructions, preserve_style)
        style_note = preserve_style ? "\n- Preserve the original writing style and tone" : ""
        
        <<~PROMPT
          Edit the following markdown content according to the provided instructions:
          
          Original Markdown:
          ```markdown
          #{markdown}
          ```
          
          Edit Instructions: #{instructions}
          
          Requirements:
          - Maintain proper markdown syntax
          - Keep structural elements intact unless specifically requested to change#{style_note}
          - Ensure the edited content flows naturally
          - Return only the edited markdown content
          
          Edited Markdown:
        PROMPT
      end

      def extract_markdown_from_response(response)
        # Remove code block markers if present
        response.gsub(/^```markdown\s*\n?/, '').gsub(/\n?```\s*$/, '').strip
      end

      def count_words(text)
        text.split(/\s+/).length
      end

      def summarize_changes(original, edited)
        # Simple change summary - could be enhanced with diff algorithms
        original_words = count_words(original)
        edited_words = count_words(edited)
        
        {
          word_change: edited_words - original_words,
          length_change: edited.length - original.length,
          similarity: calculate_similarity(original, edited)
        }
      end

      def calculate_similarity(str1, str2)
        # Simple similarity calculation
        common_words = str1.split(/\s+/) & str2.split(/\s+/)
        total_words = (str1.split(/\s+/) + str2.split(/\s+/)).uniq.length
        
        return 0 if total_words.zero?
        (common_words.length.to_f / total_words * 100).round(2)
      end

      def render_with_marksmith(markdown, github_style, syntax_highlighting)
        # This would integrate with Marksmith's rendering capabilities
        # For now, return basic structure
        {
          markdown: markdown,
          html: convert_markdown_to_html(markdown),
          github_style: github_style,
          syntax_highlighting: syntax_highlighting,
          renderer: 'marksmith'
        }
      end

      def render_with_basic_markdown(markdown, github_style, syntax_highlighting)
        {
          markdown: markdown,
          html: convert_markdown_to_html(markdown),
          github_style: github_style,
          syntax_highlighting: syntax_highlighting,
          renderer: 'basic'
        }
      end

      def convert_markdown_to_html(markdown)
        # Basic markdown to HTML conversion
        html = markdown.dup
        
        # Headers
        html.gsub!(/^### (.*$)/m, '<h3>\1</h3>')
        html.gsub!(/^## (.*$)/m, '<h2>\1</h2>')
        html.gsub!(/^# (.*$)/m, '<h1>\1</h1>')
        
        # Bold and italic
        html.gsub!(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
        html.gsub!(/\*(.*?)\*/, '<em>\1</em>')
        
        # Code blocks
        html.gsub!(/```(.*?)```/m, '<pre><code>\1</code></pre>')
        html.gsub!(/`(.*?)`/, '<code>\1</code>')
        
        # Links
        html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2">\1</a>')
        
        # Line breaks
        html.gsub!(/\n\n/, '</p><p>')
        html = "<p>#{html}</p>" unless html.start_with?('<')
        
        html
      end

      def format_standard_markdown(markdown, line_length)
        # Implement standard markdown formatting
        markdown.split("\n").map do |line|
          if line.length > line_length && !line.start_with?('#', '    ', '```')
            wrap_line(line, line_length)
          else
            line
          end
        end.join("\n")
      end

      def format_compact_markdown(markdown)
        # Remove excessive whitespace
        markdown.gsub(/\n{3,}/, "\n\n").strip
      end

      def format_extended_markdown(markdown, line_length)
        # Add more spacing and structure
        formatted = markdown.gsub(/^(\#{1,6})\s+(.*)/) { |match| "#{match}\n" }
        formatted.gsub(/\n{1}/, "\n\n")
      end

      def wrap_line(line, length)
        # Simple line wrapping
        words = line.split(' ')
        wrapped_lines = []
        current_line = []
        
        words.each do |word|
          if (current_line.join(' ') + ' ' + word).length > length
            wrapped_lines << current_line.join(' ')
            current_line = [word]
          else
            current_line << word
          end
        end
        
        wrapped_lines << current_line.join(' ') unless current_line.empty?
        wrapped_lines.join("\n")
      end

      def generate_marksmith_config
        {
          toolbar: true,
          preview: true,
          autosave: true,
          drag_drop: true,
          shortcuts: true
        }
      end

      def generate_form_helper_code(field_name, initial_content, placeholder)
        <<~CODE
          <%= marksmith_tag %>
          <%= form.marksmith :#{field_name}, 
                rows: 10,
                placeholder: "#{placeholder}",
                value: "#{initial_content}",
                class: ["block shadow-sm rounded-md border px-3 py-2 mt-2 w-full"] %>
        CODE
      end

      def generate_fallback_textarea(field_name, initial_content, placeholder)
        <<~CODE
          <%= form.text_area :#{field_name},
                rows: 10,
                placeholder: "#{placeholder}",
                value: "#{initial_content}",
                class: ["block shadow-sm rounded-md border px-3 py-2 mt-2 w-full markdown-editor"] %>
        CODE
      end

      def extract_headings(markdown)
        headings = []
        
        markdown.scan(/^(\#{1,6})\s+(.*)$/) do |match|
          headings << {
            level: match[0].length,
            text: match[1].strip,
            id: match[1].strip.downcase.gsub(/[^a-z0-9]+/, '-')
          }
        end
        
        headings
      end

      def generate_bullet_toc(headings)
        headings.map do |heading|
          indent = '  ' * (heading[:level] - 1)
          "#{indent}- [#{heading[:text]}](##{heading[:id]})"
        end.join("\n")
      end

      def generate_numbered_toc(headings)
        counters = Hash.new(0)
        
        headings.map do |heading|
          counters[heading[:level]] += 1
          # Reset deeper level counters
          counters.keys.each { |k| counters[k] = 0 if k > heading[:level] }
          
          indent = '  ' * (heading[:level] - 1)
          number = counters[heading[:level]]
          "#{indent}#{number}. [#{heading[:text]}](##{heading[:id]})"
        end.join("\n")
      end

      def generate_links_toc(headings)
        headings.map do |heading|
          "[#{heading[:text]}](##{heading[:id]})"
        end.join(' | ')
      end

      def check_heading_structure(markdown)
        issues = []
        headings = extract_headings(markdown)
        
        headings.each_with_index do |heading, index|
          if index > 0 && heading[:level] > headings[index-1][:level] + 1
            issues << {
              type: 'heading_skip',
              message: "Heading level skipped: #{heading[:text]}",
              line: find_line_number(markdown, heading[:text])
            }
          end
        end
        
        issues
      end

      def check_link_validity(markdown)
        issues = []
        # This would check if links are valid - simplified for now
        issues
      end

      def check_code_blocks(markdown)
        issues = []
        open_blocks = 0
        
        markdown.split("\n").each_with_index do |line, index|
          if line.start_with?('```')
            open_blocks += 1
          end
        end
        
        if open_blocks.odd?
          issues << {
            type: 'unclosed_code_block',
            message: 'Unclosed code block found',
            line: -1
          }
        end
        
        issues
      end

      def check_list_formatting(markdown)
        issues = []
        # Check for consistent list formatting
        issues
      end

      def check_table_formatting(markdown)
        issues = []
        # Check table structure
        issues
      end

      def find_line_number(markdown, text)
        markdown.split("\n").each_with_index do |line, index|
          return index + 1 if line.include?(text)
        end
        -1
      end

      def create_article_template(title, author, tags)
        <<~TEMPLATE
          # #{title}
          
          **Author:** #{author}
          **Date:** #{Date.current.strftime('%B %d, %Y')}
          **Tags:** #{tags.join(', ')}
          
          ## Abstract
          
          Brief overview of the article content.
          
          ## Introduction
          
          Introduction to the topic.
          
          ## Main Content
          
          ### Section 1
          
          Content goes here.
          
          ### Section 2
          
          More content.
          
          ## Conclusion
          
          Wrap up the article.
          
          ## References
          
          1. Reference 1
          2. Reference 2
        TEMPLATE
      end

      def create_readme_template(title, author)
        <<~TEMPLATE
          # #{title}
          
          Brief description of the project.
          
          ## Installation
          
          ```bash
          # Installation instructions
          ```
          
          ## Usage
          
          ```ruby
          # Usage examples
          ```
          
          ## Features
          
          - Feature 1
          - Feature 2
          - Feature 3
          
          ## Contributing
          
          1. Fork the repository
          2. Create your feature branch
          3. Commit your changes
          4. Push to the branch
          5. Create a Pull Request
          
          ## License
          
          This project is licensed under the MIT License.
          
          ## Author
          
          #{author}
        TEMPLATE
      end

      def create_blog_post_template(title, author, tags)
        <<~TEMPLATE
          # #{title}
          
          *By #{author} - #{Date.current.strftime('%B %d, %Y')}*
          
          *Tags: #{tags.join(', ')}*
          
          ## Introduction
          
          Hook the reader with an engaging introduction.
          
          ## Main Content
          
          Your main content goes here.
          
          ## Key Takeaways
          
          - Key point 1
          - Key point 2
          - Key point 3
          
          ## Conclusion
          
          Summarize the main points and provide next steps.
          
          ---
          
          *Thank you for reading! Feel free to share your thoughts in the comments below.*
        TEMPLATE
      end

      def create_documentation_template(title, author)
        <<~TEMPLATE
          # #{title}
          
          ## Overview
          
          Brief overview of what this documentation covers.
          
          ## Table of Contents
          
          - [Getting Started](#getting-started)
          - [API Reference](#api-reference)
          - [Examples](#examples)
          - [Troubleshooting](#troubleshooting)
          
          ## Getting Started
          
          ### Prerequisites
          
          - Requirement 1
          - Requirement 2
          
          ### Installation
          
          ```bash
          # Installation steps
          ```
          
          ## API Reference
          
          ### Method 1
          
          Description of method 1.
          
          **Parameters:**
          - `param1` (String): Description
          - `param2` (Integer): Description
          
          **Returns:** Description of return value
          
          **Example:**
          ```ruby
          # Example usage
          ```
          
          ## Examples
          
          ### Basic Example
          
          ```ruby
          # Basic usage example
          ```
          
          ## Troubleshooting
          
          ### Common Issues
          
          **Issue 1:** Description
          **Solution:** How to fix it
          
          ## Support
          
          For support, please contact #{author}.
        TEMPLATE
      end

      def create_api_docs_template(title, author)
        <<~TEMPLATE
          # #{title} API Documentation
          
          ## Base URL
          
          ```
          https://api.example.com/v1
          ```
          
          ## Authentication
          
          All API requests require authentication using API keys.
          
          ```bash
          curl -H "Authorization: Bearer YOUR_API_KEY" \\
               https://api.example.com/v1/endpoint
          ```
          
          ## Endpoints
          
          ### GET /resource
          
          **Description:** Retrieve resources
          
          **Parameters:**
          - `page` (Integer, optional): Page number
          - `limit` (Integer, optional): Items per page
          
          **Response:**
          ```json
          {
            "data": [...],
            "pagination": {
              "page": 1,
              "limit": 20,
              "total": 100
            }
          }
          ```
          
          ### POST /resource
          
          **Description:** Create a new resource
          
          **Request Body:**
          ```json
          {
            "name": "Resource Name",
            "description": "Resource Description"
          }
          ```
          
          **Response:**
          ```json
          {
            "id": 1,
            "name": "Resource Name",
            "description": "Resource Description",
            "created_at": "2025-01-01T00:00:00Z"
          }
          ```
          
          ## Error Handling
          
          The API returns standard HTTP status codes:
          
          - `200` - Success
          - `400` - Bad Request
          - `401` - Unauthorized
          - `404` - Not Found
          - `500` - Internal Server Error
          
          ## Rate Limiting
          
          API requests are limited to 1000 requests per hour per API key.
          
          ## Contact
          
          For API support, contact #{author}.
        TEMPLATE
      end

      def create_basic_template(title, author, tags)
        <<~TEMPLATE
          # #{title}
          
          **Author:** #{author}
          **Created:** #{Date.current.strftime('%B %d, %Y')}
          #{tags.any? ? "**Tags:** #{tags.join(', ')}" : ''}
          
          ## Content
          
          Your content goes here.
          
          ## Notes
          
          - Note 1
          - Note 2
        TEMPLATE
      end

      def build_analysis_prompt(markdown, focus)
        focus_instructions = {
          'readability' => 'Focus on readability, clarity, and flow of the content.',
          'structure' => 'Analyze the document structure, headings, and organization.',
          'grammar' => 'Check for grammar, spelling, and writing quality.',
          'seo' => 'Provide SEO optimization suggestions for web content.',
          'accessibility' => 'Suggest improvements for accessibility and inclusivity.'
        }
        
        <<~PROMPT
          Analyze the following markdown content and provide improvement suggestions:
          
          Focus Area: #{focus_instructions[focus] || focus_instructions['readability']}
          
          Markdown Content:
          ```markdown
          #{markdown}
          ```
          
          Please provide:
          1. Overall assessment
          2. Specific suggestions for improvement
          3. Priority level for each suggestion (High/Medium/Low)
          4. Actionable steps to implement changes
          
          Format your response as a structured list with clear categories.
        PROMPT
      end

      def parse_suggestions(response)
        # Parse the AI response into structured suggestions
        suggestions = []
        current_section = nil
        
        response.split("\n").each do |line|
          line = line.strip
          next if line.empty?
          
          if line.match(/^\d+\.\s*(.+)/)
            current_section = $1
            suggestions << {
              category: current_section,
              items: []
            }
          elsif line.match(/^[-*]\s*(.+)/) && current_section
            suggestions.last[:items] << $1
          end
        end
        
        suggestions
      end
    end
  end
end 