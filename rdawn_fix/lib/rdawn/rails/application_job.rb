# frozen_string_literal: true

module Rdawn
  module Rails
    class ApplicationJob < ActiveJob::Base

      queue_as do
        Rdawn::Rails.configuration.default_queue_name
      end
      
      retry_on StandardError, wait: :exponentially_longer, attempts: 3
      discard_on Rdawn::Errors::ConfigurationError
      discard_on Rdawn::Errors::VariableResolutionError
      
      rescue_from StandardError do |exception|
        ::Rails.logger.error "[DEBUG] Final rescue block caught: #{exception.class.name} - #{exception.message}"
        ::Rails.logger.error exception.backtrace.join("\n")
        raise exception
      end
      
      protected
      
      def safe_workflow_execution(&block)
        begin
          yield
        rescue Rdawn::Errors::RdawnError => e
          ::Rails.logger.error "Rdawn workflow error: #{e.class.name} - #{e.message}"
          raise e
        rescue StandardError => e
          ::Rails.logger.error "Unexpected error in rdawn workflow: #{e.class.name} - #{e.message}"
          raise Rdawn::Errors::TaskExecutionError, "Workflow execution failed: #{e.message}"
        end
      end
      
      def build_workflow_context(additional_context = {})
        {
          rails_env: ::Rails.env,
          timestamp: Time.current,
          job_id: job_id,
          job_class: self.class.name
        }.merge(additional_context)
      end
    end
  end
end