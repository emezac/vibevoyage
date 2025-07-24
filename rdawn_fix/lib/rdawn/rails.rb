# frozen_string_literal: true

require_relative "rails/application_job"
require_relative "rails/workflow_job"
require_relative "rails/tools"

# Solo cargar el generador si se está ejecutando un comando de generación
if defined?(Rails::Generators)
  require_relative "rails/generators/install_generator"
end
# frozen_string_literal: true

# Only load Rails integration if Rails is available
begin
  require 'rails'
  require 'active_job'
rescue LoadError
  # Rails not available, skip Rails integration
  return
end

module Rdawn
  module Rails
    # Configuration class for Rails-specific settings
    class Configuration
      attr_accessor :default_queue_adapter, :default_queue_name, :enable_active_job_integration
      
      def initialize
        @default_queue_adapter = :async
        @default_queue_name = :rdawn
        @enable_active_job_integration = true
      end
    end
    
    # Rails configuration
    def self.configuration
      @configuration ||= Configuration.new
    end
    
    def self.configure
      yield(configuration)
    end
    
    # Railtie for Rails initialization
    class Railtie < ::Rails::Railtie
      railtie_name :rdawn
      
      config.rdawn = Rdawn::Rails.configuration
      
      initializer "rdawn.configure" do |app|
        # Set up rdawn configuration based on Rails environment
        Rdawn::Rails.configure do |config|
          config.default_queue_adapter = app.config.active_job.queue_adapter || :async
          config.default_queue_name = app.config.rdawn&.default_queue_name || :rdawn
          config.enable_active_job_integration = app.config.rdawn&.enable_active_job_integration != false
        end
      end
      
      initializer "rdawn.active_job" do
        # Register rdawn jobs if Active Job integration is enabled
        if Rdawn::Rails.configuration.enable_active_job_integration
          ActiveSupport.on_load(:active_job) do
            # Ensure our job classes are loaded
            require 'rdawn/rails/application_job'
            require 'rdawn/rails/workflow_job'
          end
        end
      end

      initializer "rdawn.register_rails_tools" do
        # Register Rails-specific tools after Rails is fully loaded
        ActiveSupport.on_load(:active_record) do
          if defined?(Rails) && Rails.respond_to?(:logger)
            # Register ActionCableTool for real-time UI updates
            if defined?(::Turbo) && defined?(::ActionCable)
              action_cable_tool = Rdawn::Rails::Tools::ActionCableTool.new
              Rdawn::ToolRegistry.register('action_cable', action_cable_tool.method(:call))
              Rdawn::ToolRegistry.register('turbo_stream', action_cable_tool.method(:call))
              ::Rails.logger.debug "Rdawn: ActionCableTool registered successfully"
            else
              ::Rails.logger.warn "Rdawn: ActionCableTool not registered - Turbo or ActionCable not available"
            end

            # Register PunditPolicyTool for authorization verification
            if defined?(::Pundit)
              pundit_tool = Rdawn::Rails::Tools::PunditPolicyTool.new
              Rdawn::ToolRegistry.register('pundit_check', pundit_tool.method(:call))
              ::Rails.logger.debug "Rdawn: PunditPolicyTool registered successfully"
            else
              ::Rails.logger.warn "Rdawn: PunditPolicyTool not registered - Pundit gem not available"
            end

            # Register ActiveRecordScopeTool for safe database querying
            scope_tool = Rdawn::Rails::Tools::ActiveRecordScopeTool.new
            Rdawn::ToolRegistry.register('active_record_scope', scope_tool.method(:call))
            ::Rails.logger.debug "Rdawn: ActiveRecordScopeTool registered successfully"

            # Register ActionMailerTool for professional email communication
            if defined?(ActionMailer::Base)
              mailer_tool = Rdawn::Rails::Tools::ActionMailerTool.new
              Rdawn::ToolRegistry.register('action_mailer_send', mailer_tool.method(:call))
              ::Rails.logger.debug "Rdawn: ActionMailerTool registered successfully"
            else
              ::Rails.logger.warn "Rdawn: ActionMailerTool not registered - ActionMailer not available"
            end
          end
        end
      end
      
      generators do
        require 'rdawn/rails/generators/install_generator'
      end
    end
  end
end

# Load Rails-specific components
require 'rdawn/rails/application_job'
require 'rdawn/rails/tools/action_cable_tool' if defined?(Rails)
require 'rdawn/rails/tools/pundit_policy_tool' if defined?(Rails)
require 'rdawn/rails/tools/active_record_scope_tool' if defined?(Rails)
require 'rdawn/rails/tools/action_mailer_tool' if defined?(Rails)
require 'rdawn/rails/workflow_job' 