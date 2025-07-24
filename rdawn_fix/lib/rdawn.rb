# frozen_string_literal: true

require_relative "rdawn/version"
require_relative "rdawn/errors"
require_relative "rdawn/agent"
require_relative "rdawn/task"
require_relative "rdawn/tools"
require_relative "rdawn/tool_registry"
require_relative "rdawn/workflow"
require_relative "rdawn/workflow_engine"
require_relative "rdawn/variable_resolver"
require_relative "rdawn/llm_interface"
require_relative "rdawn/mcp_manager"

# Rails integration y generadores
if defined?(Rails)
  require "rdawn/rails"
end
module Rdawn
  class Error < StandardError; end
  
  # Configuration class for rdawn
  class Configuration
    attr_accessor :llm_api_key, :llm_model, :llm_provider, :default_model_params, :active_record_scope_tool
    
    def initialize
      @llm_api_key = nil
      @llm_model = 'gpt-4o-mini'
      @llm_provider = 'openrouter'
      @default_model_params = {
        temperature: 0.7,
        max_tokens: 1000
      }
      @active_record_scope_tool = {}
    end
  end
  
  # Global configuration
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
    configure_raix_global
  end
  
  def self.config
    configuration
  end
  
  private
  
  def self.configure_raix_global
    # Skip Raix configuration - using direct OpenAI API integration
    # This avoids parameter compatibility issues with external libraries
    puts "Rdawn: Using direct OpenAI API integration (Raix bypassed)" if ENV['RDAWN_DEBUG']
  end
end
