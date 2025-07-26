require 'httpx'

class MapsApiTool
  API_KEY = ENV['GOOGLE_PLACES_API_KEY']
  API_SERVER = 'https://maps.googleapis.com/maps/api/place'

  def self.execute(input)
    query = input[:query]
    
    if query.blank?
      return { success: false, error: 'Query parameter is required' }
    end

    begin
      # Usar Google Places Text Search API
      params = {
        query: query,
        key: API_KEY,
        fields: 'place_id,name,formatted_address,geometry,rating,editorial_summary,address_components'
      }

      Rails.logger.info "Making Google Places API request for: #{query}"
      
      response = HTTPX.with(headers: {
        'Content-Type' => 'application/json'
      }).get("#{API_SERVER}/textsearch/json", params: params)

      # FIX: Verificar si es un ErrorResponse antes de acceder a status
      if response.is_a?(HTTPX::ErrorResponse)
        error_msg = response.error&.message || response.error.to_s || "Unknown HTTPX error"
        Rails.logger.error "Google Places API HTTPX error: #{error_msg}"
        return { success: false, error: "Network error: #{error_msg}" }
      end

      # Solo acceder a status si no es un ErrorResponse
      if response.status == 200
        data = JSON.parse(response.body.to_s)
        
        if data['status'] == 'OK'
          Rails.logger.info "Google Places API success: #{data['results'].size} results found"
          { success: true, data: data }
        else
          Rails.logger.error "Google Places API error: #{data['status']} - #{data['error_message']}"
          { success: false, error: "Google Places API error: #{data['status']}" }
        end
      else
        Rails.logger.error "Google Places API HTTP error: #{response.status}"
        { success: false, error: "HTTP #{response.status}: #{response.body}" }
      end
      
    rescue => e
      Rails.logger.error "Google Places API exception: #{e.message}"
      { success: false, error: "Exception: #{e.message}" }
    end
  end

  # Ejemplo de método para buscar lugares (método legacy para compatibilidad)
  def self.search_places(params = {})
    response = HTTPX.with(headers: {
      'Content-Type' => 'application/json'
    }).get("#{API_SERVER}/textsearch/json", params: params.merge(key: API_KEY))

    # FIX: Verificar si es un ErrorResponse antes de acceder a status
    if response.is_a?(HTTPX::ErrorResponse)
      error_msg = response.error&.message || response.error.to_s || "Unknown HTTPX error"
      return { error: 'network_error', message: error_msg }
    end

    if response.status == 200
      JSON.parse(response.body.to_s)
    else
      { error: response.status, body: response.body.to_s }
    end
  rescue => e
    { error: 'exception', message: e.message }
  end
end
