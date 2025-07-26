# app/tools/qloo_api_tool.rb
# frozen_string_literal: true

require 'httpx'
require 'json'

class QlooApiTool
  API_SERVER = 'https://hackathon.api.qloo.com'
  INSIGHTS_ENDPOINT = '/v2/insights'
  DEFAULT_ENTITY_TYPE = 'urn:entity:place'

  def initialize(api_key:)
    if api_key.blank?
      raise Rdawn::Errors::ConfigurationError, 'La clave de API de Qloo es requerida.'
    end
    @api_key = api_key
  end

  def recommendations(params = {})
    interests = params[:interests] || params['interests']
    city = params[:city] || params['city']
    # AÑADIMOS LAS PREFERENCIAS
    preferences = params[:preferences] || params['preferences'] || []

    if interests.blank? || city.blank?
      return { success: false, error: 'Se requieren "interests" y "city".' }
    end

    # --- CUERPO DE LA PETICIÓN MEJORADO ---
    body = {
      'filter.type' => DEFAULT_ENTITY_TYPE,
      'signal.interests.entities.query' => interests,
      'filter.location.query' => city,
      'take' => 10
    }
    # Si tenemos preferencias, las añadimos como un filtro de categoría adicional
    body['filter.category.query'] = preferences unless preferences.empty?
    # --- FIN DE LA MEJORA ---

    execute_request(body)
  end

  private

  def execute_request(body)
    headers = { 'X-Api-Key' => @api_key, 'Content-Type' => 'application/json' }
    response = HTTPX.with(headers: headers).post("#{API_SERVER}#{INSIGHTS_ENDPOINT}", json: body)

    # FIX: Verificar si es un ErrorResponse antes de acceder a status
    if response.is_a?(HTTPX::ErrorResponse)
      error_msg = response.error&.message || response.error.to_s || "Unknown HTTPX error"
      return { success: false, error: "Network error: #{error_msg}" }
    end

    # Solo acceder a status si no es un ErrorResponse
    if response.status == 200
      { success: true, data: JSON.parse(response.body.to_s) }
    else
      { success: false, error: "Qloo API Error: #{response.status}", body: response.body.to_s, sent_params: body }
    end
  rescue HTTPX::Error, JSON::ParserError => e
    { success: false, error: 'Exception', message: e.message }
  end
end