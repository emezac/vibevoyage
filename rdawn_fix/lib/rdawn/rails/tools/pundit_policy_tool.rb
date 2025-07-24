# frozen_string_literal: true

module Rdawn
  module Rails
    module Tools
      # PunditPolicyTool - Authorization verification for secure agent operations
      #
      # This tool integrates with Pundit authorization to ensure agents operate
      # under the same security constraints as human users. It verifies permissions
      # before allowing agents to perform actions on resources.
      #
      # @example Basic usage
      #   tool.call({
      #     user: current_user,
      #     record: @project,
      #     action: 'update?'
      #   })
      #   # => { success: true, authorized: true, error: nil }
      #
      # @example Permission denied
      #   tool.call({
      #     user: guest_user,
      #     record: @admin_project,
      #     action: 'destroy?'
      #   })
      #   # => { success: true, authorized: false, error: nil }
      #
      class PunditPolicyTool
        # Verify user authorization for a specific action on a record
        #
        # @param input [Hash] The input parameters
        # @option input [Object] :user The User object performing the action
        # @option input [Object] :record The Active Record object being acted upon
        # @option input [String, Symbol] :action The policy method to check (e.g., 'update?')
        # @return [Hash] Result hash with success, authorized, and error fields
        def call(input)
          # Validate required parameters
          validation_result = validate_input(input)
          return validation_result unless validation_result[:success]

          user = input[:user]
          record = input[:record]
          action = input[:action].to_s

          # Ensure action ends with '?' as per Pundit convention
          action = "#{action}?" unless action.end_with?('?')

          begin
            # Check if Pundit is available
            unless defined?(::Pundit)
              return {
                success: false,
                authorized: false,
                error: "Pundit gem is not available. Add 'gem pundit' to your Gemfile."
              }
            end

            # Get the policy for this user and record
            policy = ::Pundit.policy!(user, record)
            
            # Check if the policy responds to the action method
            unless policy.respond_to?(action)
              return {
                success: false,
                authorized: false,
                error: "Policy #{policy.class.name} does not define method '#{action}'"
              }
            end

            # Execute the authorization check
            authorized = policy.public_send(action)

            {
              success: true,
              authorized: !!authorized, # Convert to boolean
              error: nil,
              policy_class: policy.class.name,
              user_id: user.respond_to?(:id) ? user.id : nil,
              record_class: record.class.name,
              record_id: record.respond_to?(:id) ? record.id : nil,
              action: action
            }

          rescue ::Pundit::NotDefinedError => e
            {
              success: false,
              authorized: false,
              error: "Policy not found: #{e.message}"
            }
          rescue ::Pundit::NotAuthorizedError => e
            # This shouldn't happen with policy! but handle it gracefully
            {
              success: true,
              authorized: false,
              error: nil,
              policy_class: e.policy.class.name,
              action: action
            }
          rescue StandardError => e
            {
              success: false,
              authorized: false,
              error: "Authorization check failed: #{e.message}"
            }
          end
        end

        private

        # Validate input parameters
        #
        # @param input [Hash] The input parameters to validate
        # @return [Hash] Validation result
        def validate_input(input)
          unless input.is_a?(Hash)
            return {
              success: false,
              authorized: false,
              error: "Input must be a hash"
            }
          end

          # Check required parameters
          required_params = [:user, :record, :action]
          missing_params = required_params.select { |param| input[param].nil? }

          unless missing_params.empty?
            return {
              success: false,
              authorized: false,
              error: "Missing required parameters: #{missing_params.join(', ')}"
            }
          end

          # Validate user object
          unless input[:user].respond_to?(:id)
            return {
              success: false,
              authorized: false,
              error: "User object must respond to :id method"
            }
          end

          # Validate record object (can be a class or instance)
          record = input[:record]
          unless record.respond_to?(:class) || record.is_a?(Class)
            return {
              success: false,
              authorized: false,
              error: "Record must be an object or class"
            }
          end

          # Validate action parameter
          action = input[:action]
          unless action.is_a?(String) || action.is_a?(Symbol)
            return {
              success: false,
              authorized: false,
              error: "Action must be a string or symbol"
            }
          end

          if action.to_s.strip.empty?
            return {
              success: false,
              authorized: false,
              error: "Action cannot be empty"
            }
          end

          { success: true }
        end
      end
    end
  end
end 