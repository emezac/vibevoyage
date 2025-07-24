# frozen_string_literal: true

module Rdawn
  module Rails
    module Tools
      # ActiveRecordScopeTool - Safe database querying with business logic encapsulation
      #
      # This tool allows AI agents to query databases using predefined ActiveRecord scopes
      # rather than constructing raw SQL. It provides a security layer and keeps business
      # logic where it belongs: in the models.
      #
      # @example Basic usage
      #   tool.call({
      #     model_name: 'Lead',
      #     scopes: [
      #       { name: 'high_priority', args: [] },
      #       { name: 'assigned_to', args: [user_id] }
      #     ]
      #   })
      #   # => { success: true, results: [...], count: 5 }
      #
      # @example Business-focused queries
      #   tool.call({
      #     model_name: 'Lead',
      #     scopes: [
      #       { name: 'hot_leads' },
      #       { name: 'from_campaign', args: ['email_marketing'] },
      #       { name: 'requiring_followup' }
      #     ]
      #   })
      #
      class ActiveRecordScopeTool
        # Default configuration - can be overridden via Rdawn.configure
        DEFAULT_CONFIG = {
          # Models that can be queried
          allowed_models: [],
          
          # Scopes that can be used per model
          allowed_scopes: {},
          
          # Maximum number of records to return
          max_results: 100,
          
          # Whether to include record count in response
          include_count: true,
          
          # Default fields to exclude from results (sensitive data)
          excluded_fields: ['password', 'password_digest', 'encrypted_password', 'password_salt'],
          
          # Enable/disable scope chaining
          allow_scope_chaining: true
        }.freeze

        # Query database using predefined ActiveRecord scopes
        #
        # @param input [Hash] The input parameters
        # @option input [String] :model_name The model class name (e.g., 'Lead', 'User')
        # @option input [Array<Hash>] :scopes Array of scope definitions
        # @option input [Integer] :limit Optional limit override (respects max_results)
        # @option input [Array<String>] :only_fields Optional field whitelist
        # @option input [Array<String>] :except_fields Additional fields to exclude
        # @return [Hash] Result hash with success, results, count, and metadata
        def call(input)
          # Validate input parameters
          validation_result = validate_input(input)
          return validation_result unless validation_result[:success]

          model_name = input[:model_name]
          scopes = input[:scopes] || []
          limit = input[:limit]
          only_fields = input[:only_fields]
          except_fields = input[:except_fields] || []

          begin
            # Get model class safely
            model_class = safe_constantize_model(model_name)
            return model_class unless model_class[:success]
            
            model = model_class[:model]

            # Validate model is allowed
            unless model_allowed?(model)
              return {
                success: false,
                error: "Model '#{model_name}' is not in the allowed models list. Configure allowed_models in Rdawn.configure.",
                allowed_models: config[:allowed_models]
              }
            end

            # Build the query by chaining scopes
            query_result = build_scoped_query(model, scopes)
            return query_result unless query_result[:success]

            relation = query_result[:relation]

            # Apply limit
            final_limit = determine_limit(limit)
            relation = relation.limit(final_limit) if final_limit

            # Execute query and format results
            records = relation.to_a
            count = config[:include_count] ? relation.limit(nil).count : records.length

            # Format results for AI consumption
            formatted_results = format_results(
              records, 
              only_fields: only_fields, 
              except_fields: except_fields + config[:excluded_fields]
            )

            {
              success: true,
              results: formatted_results,
              count: count,
              model: model_name,
              scopes_applied: scopes.map { |s| scope_signature(s) },
              total_available: count,
              returned: records.length,
              limited: records.length >= final_limit.to_i,
              metadata: {
                executed_at: Time.current.iso8601,
                query_time_ms: nil # Could add query timing if needed
              }
            }

          rescue ActiveRecord::StatementInvalid => e
            {
              success: false,
              error: "Database query failed: #{e.message}",
              type: 'database_error'
            }
          rescue StandardError => e
            {
              success: false,
              error: "Scope execution failed: #{e.message}",
              type: 'execution_error'
            }
          end
        end

        private

        # Get configuration from Rdawn or use defaults
        def config
          @config ||= begin
            if defined?(::Rdawn) && ::Rdawn.respond_to?(:configuration) && ::Rdawn.configuration.respond_to?(:active_record_scope_tool)
              DEFAULT_CONFIG.merge(::Rdawn.configuration.active_record_scope_tool || {})
            else
              DEFAULT_CONFIG
            end
          end
        end

        # Validate input parameters
        def validate_input(input)
          unless input.is_a?(Hash)
            return {
              success: false,
              error: "Input must be a hash"
            }
          end

          # Check required parameters
          unless input[:model_name].present?
            return {
              success: false,
              error: "Missing required parameter: model_name"
            }
          end

          # Validate model_name format
          unless input[:model_name].is_a?(String) && input[:model_name].match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
            return {
              success: false,
              error: "model_name must be a valid Ruby class name (e.g., 'Lead', 'User')"
            }
          end

          # Validate scopes format
          if input[:scopes] && !input[:scopes].is_a?(Array)
            return {
              success: false,
              error: "scopes must be an array of scope definitions"
            }
          end

          # Validate individual scopes
          if input[:scopes]
            input[:scopes].each_with_index do |scope, index|
              unless scope.is_a?(Hash) && scope[:name].present?
                return {
                  success: false,
                  error: "Scope at index #{index} must be a hash with a 'name' key"
                }
              end

              unless scope[:name].is_a?(String) || scope[:name].is_a?(Symbol)
                return {
                  success: false,
                  error: "Scope name at index #{index} must be a string or symbol"
                }
              end

              if scope[:args] && !scope[:args].is_a?(Array)
                return {
                  success: false,
                  error: "Scope args at index #{index} must be an array"
                }
              end
            end
          end

          { success: true }
        end

        # Safely convert string to model class
        def safe_constantize_model(model_name)
          begin
            model = model_name.safe_constantize
            
            unless model
              return {
                success: false,
                error: "Model '#{model_name}' not found. Make sure the model exists and is loaded."
              }
            end

            unless model.respond_to?(:scoped) || model < ActiveRecord::Base
              return {
                success: false,
                error: "#{model_name} is not an ActiveRecord model"
              }
            end

            { success: true, model: model }
          rescue NameError => e
            {
              success: false,
              error: "Invalid model name '#{model_name}': #{e.message}"
            }
          end
        end

        # Check if model is in allowed list
        def model_allowed?(model)
          allowed_models = config[:allowed_models]
          
          # If no restrictions, allow everything (not recommended for production)
          return true if allowed_models.empty?
          
          # Check if model name is in allowed list
          allowed_models.include?(model.name)
        end

        # Check if scope is allowed for the model
        def scope_allowed?(model, scope_name)
          allowed_scopes = config[:allowed_scopes]
          
          # If no scope restrictions, allow all scopes on allowed models
          return true if allowed_scopes.empty?
          
          # Check if scope is allowed for this model
          model_scopes = allowed_scopes[model.name] || []
          model_scopes.include?(scope_name.to_s) || model_scopes.include?(scope_name.to_sym)
        end

        # Build ActiveRecord query by chaining scopes
        def build_scoped_query(model, scopes)
          relation = model.all

          scopes.each_with_index do |scope_def, index|
            scope_name = scope_def[:name].to_sym
            scope_args = scope_def[:args] || []

            # Validate scope is allowed
            unless scope_allowed?(model, scope_name)
              return {
                success: false,
                error: "Scope '#{scope_name}' is not allowed for model '#{model.name}'. Configure allowed_scopes in Rdawn.configure.",
                allowed_scopes: config[:allowed_scopes][model.name] || []
              }
            end

            # Check if scope exists on the model
            unless model.respond_to?(scope_name)
              return {
                success: false,
                error: "Scope '#{scope_name}' does not exist on model '#{model.name}'. Available scopes: #{available_scopes(model).join(', ')}"
              }
            end

            begin
              # Apply the scope
              if scope_args.any?
                relation = relation.public_send(scope_name, *scope_args)
              else
                relation = relation.public_send(scope_name)
              end
            rescue ArgumentError => e
              return {
                success: false,
                error: "Invalid arguments for scope '#{scope_name}': #{e.message}"
              }
            rescue StandardError => e
              return {
                success: false,
                error: "Error applying scope '#{scope_name}': #{e.message}"
              }
            end
          end

          { success: true, relation: relation }
        end

        # Determine the appropriate limit for results
        def determine_limit(requested_limit)
          max_limit = config[:max_results]
          
          if requested_limit
            # Use the smaller of requested limit and max allowed
            [requested_limit.to_i, max_limit].min
          else
            max_limit
          end
        end

        # Format results for AI consumption
        def format_results(records, only_fields: nil, except_fields: [])
          return [] if records.empty?

          # Convert to hashes
          results = records.map(&:as_json)

          # Apply field filtering
          if only_fields&.any?
            results = results.map { |record| record.slice(*only_fields.map(&:to_s)) }
          end

          if except_fields.any?
            results = results.map { |record| record.except(*except_fields.map(&:to_s)) }
          end

          results
        end

        # Get available scopes for a model (for error messages)
        def available_scopes(model)
          if model.respond_to?(:scope_registry)
            model.scope_registry.keys
          else
            # Fallback for older Rails versions
            model.methods.grep(/\Ascope_/).map { |m| m.to_s.sub(/\Ascope_/, '') }
          end
        end

        # Create a readable signature for a scope (for logging/debugging)
        def scope_signature(scope_def)
          name = scope_def[:name]
          args = scope_def[:args]
          
          if args&.any?
            "#{name}(#{args.map(&:inspect).join(', ')})"
          else
            name.to_s
          end
        end
      end
    end
  end
end 