# frozen_string_literal: true

# Rdawn Configuration
# Configure rdawn for your Rails application

# Load rdawn Rails integration
require 'rdawn/rails'

# Configure rdawn
Rdawn.configure do |config|
  # LLM Configuration
  config.llm_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
  config.llm_model = 'gpt-4o-mini'  # or 'gpt-4', 'gpt-3.5-turbo'
  config.llm_provider = 'openai'    # Actualmente solo OpenAI soportado

  # Default configuration for all agents
  config.default_model_params = {
    temperature: 0.7,
    max_tokens: 1000
  }
end

# Registrar herramientas avanzadas (opcional pero recomendado)
api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
Rdawn::Tools.register_advanced_tools(api_key: api_key)

# Configuración específica de Rails
Rdawn::Rails.configure do |config|
  # Configuración de Active Job
  config.default_queue_adapter = :async # Cambia a :sidekiq si usas Sidekiq
  config.default_queue_name = :rdawn
  config.enable_active_job_integration = true
end

# Las herramientas específicas de Rails se registran automáticamente:
# - 'action_cable' / 'turbo_stream' - Actualizaciones UI en tiempo real (requiere turbo-rails)
#
# Para habilitar características en tiempo real, agrega a tu Gemfile:
# gem 'turbo-rails'
# gem 'redis' # para Action Cable en producción

# Registro de herramientas personalizadas para el agente
require_relative '../../app/tools/qloo_api_tool'
require_relative '../../app/tools/maps_api_tool'

# FIX: Verificar que las herramientas se registren correctamente
begin
  qloo_tool_instance = QlooApiTool.new(api_key: ENV['QLOO_API_KEY']&.strip)
  Rdawn::ToolRegistry.register('qloo_api', qloo_tool_instance.method(:recommendations))
  
  # FIX: Usar el método 'execute' que maneja el formato { query: query }
  Rdawn::ToolRegistry.register('maps_api', MapsApiTool.method(:execute))
  
  Rails.logger.info "Successfully registered tools: qloo_api, maps_api"
rescue => e
  Rails.logger.error "Error registering tools: #{e.message}"
end

# Ejemplo de registro de workflow handler
# Registra tus workflow handlers aquí o en archivos separados
#
# Ejemplo:
# module WorkflowHandlers
#   class UserOnboarding
#     def self.call(input_data, workflow_variables)
#       user = User.find(input_data['user_id'])
#       # Your onboarding logic here
#       { success: true, user: user.attributes }
#     end
#   end
# end