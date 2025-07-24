# frozen_string_literal: true

module Rdawn
  module Rails
    module Tools
      # ActionMailerTool - Professional email communication through Rails infrastructure
      #
      # This tool allows AI agents to send content-rich emails using the host application's 
      # existing ActionMailer templates, layouts, and logic. It ensures brand consistency
      # and professionalism by leveraging the entire Rails email communication infrastructure.
      #
      # @example Basic usage
      #   tool.call({
      #     mailer_name: 'ProjectMailer',
      #     action_name: 'project_update_notification',
      #     params: { 
      #       project: @project, 
      #       user: @user, 
      #       message: 'Project milestone completed successfully!'
      #     },
      #     delivery_method: 'deliver_later'
      #   })
      #   # => { success: true, result: { message: "Email enqueued successfully" } }
      #
      # @example CRM workflow notification
      #   tool.call({
      #     mailer_name: 'LeadMailer',
      #     action_name: 'follow_up_reminder',
      #     params: {
      #       lead: @lead,
      #       sales_rep: @user,
      #       follow_up_date: 2.days.from_now
      #     }
      #   })
      #
      class ActionMailerTool
        # Send professional emails using Rails ActionMailer infrastructure
        #
        # @param input [Hash] The input parameters
        # @option input [String] :mailer_name The ActionMailer class name (e.g., 'ProjectMailer')
        # @option input [String, Symbol] :action_name The mailer action method (e.g., :project_update_notification)
        # @option input [Hash] :params Parameters to pass to the mailer's .with() method (can include ActiveRecord objects)
        # @option input [String] :delivery_method Optional delivery method ('deliver_later' or 'deliver_now'), defaults to 'deliver_later'
        # @return [Hash] Result hash with success status, message, and metadata
        def call(input)
          # Validate input parameters
          validation_result = validate_input(input)
          return validation_result unless validation_result[:success]

          mailer_name = input[:mailer_name]
          action_name = input[:action_name].to_sym
          params = input[:params] || {}
          delivery_method = input[:delivery_method] || 'deliver_later'

          begin
            # Get mailer class safely
            mailer_class = safe_constantize_mailer(mailer_name)
            return mailer_class unless mailer_class[:success]

            mailer = mailer_class[:mailer]

            # Validate action exists and is accessible
            action_validation = validate_mailer_action(mailer, action_name)
            return action_validation unless action_validation[:success]

            # Validate delivery method
            unless valid_delivery_method?(delivery_method)
              return {
                success: false,
                error: "Invalid delivery_method '#{delivery_method}'. Must be 'deliver_later' or 'deliver_now'.",
                valid_methods: ['deliver_later', 'deliver_now']
              }
            end

            # Build and send the email
            email_result = send_email(mailer, action_name, params, delivery_method)
            return email_result unless email_result[:success]

            # Return success result
            {
              success: true,
              result: {
                message: delivery_method == 'deliver_later' ? "Email enqueued successfully" : "Email sent successfully",
                mailer: mailer_name,
                action: action_name.to_s,
                delivery_method: delivery_method,
                params_count: params.keys.length
              },
              metadata: {
                executed_at: Time.current.iso8601,
                delivery_method: delivery_method,
                active_job_enabled: delivery_method == 'deliver_later' && active_job_available?
              }
            }

          rescue Net::SMTPAuthenticationError => e
            {
              success: false,
              error: "SMTP authentication failed: #{e.message}",
              type: 'smtp_authentication_error',
              suggestion: "Check your email server credentials in Rails configuration"
            }
          rescue Net::SMTPServerBusy => e
            {
              success: false,
              error: "SMTP server busy: #{e.message}",
              type: 'smtp_server_busy',
              suggestion: "Try again later or check your email service status"
            }
          rescue Net::SMTPSyntaxError => e
            {
              success: false,
              error: "SMTP syntax error: #{e.message}",
              type: 'smtp_syntax_error',
              suggestion: "Check email addresses and content formatting"
            }
          rescue ActionView::Template::Error => e
            {
              success: false,
              error: "Email template error: #{e.message}",
              type: 'template_error',
              suggestion: "Check the email template for the specified action"
            }
          rescue StandardError => e
            {
              success: false,
              error: "Email sending failed: #{e.message}",
              type: 'email_error'
            }
          end
        end

        private

        # Validate input parameters
        def validate_input(input)
          unless input.is_a?(Hash)
            return {
              success: false,
              error: "Input must be a hash"
            }
          end

          # Check required parameters
          required_params = [:mailer_name, :action_name]
          missing_params = required_params.select { |param| input[param].blank? }

          if missing_params.any?
            return {
              success: false,
              error: "Missing required parameters: #{missing_params.join(', ')}",
              required_parameters: required_params
            }
          end

          # Validate mailer_name format
          unless input[:mailer_name].is_a?(String) && input[:mailer_name].match?(/\A[A-Z][a-zA-Z0-9_]*Mailer\z/)
            return {
              success: false,
              error: "mailer_name must be a valid ActionMailer class name ending with 'Mailer' (e.g., 'ProjectMailer')"
            }
          end

          # Validate action_name format
          unless input[:action_name].is_a?(String) || input[:action_name].is_a?(Symbol)
            return {
              success: false,
              error: "action_name must be a string or symbol representing the mailer action method"
            }
          end

          # Validate params if provided
          if input[:params] && !input[:params].is_a?(Hash)
            return {
              success: false,
              error: "params must be a hash of parameters for the mailer"
            }
          end

          { success: true }
        end

        # Safely convert string to mailer class
        def safe_constantize_mailer(mailer_name)
          begin
            mailer_class = mailer_name.safe_constantize

            unless mailer_class
              return {
                success: false,
                error: "Mailer '#{mailer_name}' not found. Make sure the mailer class exists and is loaded.",
                suggestion: "Check that #{mailer_name} is defined in app/mailers/"
              }
            end

            # Verify it's actually an ActionMailer class
            unless mailer_class < ActionMailer::Base
              return {
                success: false,
                error: "#{mailer_name} is not an ActionMailer class",
                suggestion: "Make sure #{mailer_name} inherits from ActionMailer::Base"
              }
            end

            { success: true, mailer: mailer_class }

          rescue NameError => e
            {
              success: false,
              error: "Invalid mailer name '#{mailer_name}': #{e.message}",
              suggestion: "Use a valid Ruby class name ending with 'Mailer'"
            }
          end
        end

        # Validate that the action exists and is callable on the mailer
        def validate_mailer_action(mailer_class, action_name)
          # Check if the action method exists
          unless mailer_class.method_defined?(action_name) || mailer_class.private_method_defined?(action_name)
            available_actions = get_available_actions(mailer_class)
            return {
              success: false,
              error: "Action '#{action_name}' does not exist on mailer '#{mailer_class.name}'",
              available_actions: available_actions,
              suggestion: "Use one of the available actions: #{available_actions.join(', ')}"
            }
          end

          # Check if the action is public (ActionMailer actions should be public)
          unless mailer_class.method_defined?(action_name)
            return {
              success: false,
              error: "Action '#{action_name}' exists but is not public on mailer '#{mailer_class.name}'",
              suggestion: "Make sure the mailer action is defined as a public method"
            }
          end

          { success: true }
        end

        # Get available public actions from the mailer class
        def get_available_actions(mailer_class)
          # Get public instance methods that are likely mailer actions
          # Exclude ActionMailer::Base methods and common Ruby object methods
          excluded_methods = ActionMailer::Base.instance_methods + 
                            Object.instance_methods + 
                            [:mail, :headers, :attachments, :mailer_name, :message]

          mailer_class.public_instance_methods(false).reject do |method|
            excluded_methods.include?(method) || method.to_s.start_with?('_')
          end.sort
        end

        # Validate delivery method
        def valid_delivery_method?(delivery_method)
          %w[deliver_later deliver_now].include?(delivery_method.to_s)
        end

        # Send the email using the specified parameters
        def send_email(mailer_class, action_name, params, delivery_method)
          begin
            # Build the mailer with parameters
            mailer_instance = mailer_class.with(params)
            
            # Call the action to build the mail
            mail = mailer_instance.public_send(action_name)
            
            # Verify we got a valid Mail object
            unless mail.respond_to?(:deliver_later) && mail.respond_to?(:deliver_now)
              return {
                success: false,
                error: "Mailer action '#{action_name}' did not return a valid Mail object",
                suggestion: "Make sure your mailer action returns the result of a 'mail()' call"
              }
            end

            # Deliver the email
            case delivery_method
            when 'deliver_later'
              if active_job_available?
                mail.deliver_later
              else
                # Fallback to deliver_now if ActiveJob is not available
                mail.deliver_now
              end
            when 'deliver_now'
              mail.deliver_now
            end

            { success: true }

          rescue ArgumentError => e
            {
              success: false,
              error: "Invalid parameters for mailer action '#{action_name}': #{e.message}",
              suggestion: "Check that the parameters match what the mailer action expects"
            }
          rescue NoMethodError => e
            if e.message.include?('mail')
              {
                success: false,
                error: "Mailer action '#{action_name}' does not properly call 'mail()' method: #{e.message}",
                suggestion: "Make sure your mailer action ends with a 'mail()' call"
              }
            else
              {
                success: false,
                error: "Error executing mailer action '#{action_name}': #{e.message}"
              }
            end
          end
        end

        # Check if ActiveJob is available and configured
        def active_job_available?
          defined?(ActiveJob) && ActiveJob::Base.queue_adapter_name != :inline
        end

        # Check if ActionMailer is properly configured
        def action_mailer_configured?
          defined?(ActionMailer::Base) && 
          ActionMailer::Base.delivery_method.present? &&
          ActionMailer::Base.delivery_method != :test
        end
      end
    end
  end
end 