class RdawnApiService
  # Llama a la herramienta QlooApiTool para obtener recomendaciones culturales.
  #
  # @param interests [Array<String>] Una lista de intereses culturales.
  # @param city [String] La ciudad para la cual buscar recomendaciones.
  # @param preferences [Array<String>] (Opcional) Una lista de categorías para filtrar.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  def self.qloo_recommendations(interests:, city:, preferences: [])
    begin
      # Pasamos los tres argumentos a la herramienta.
      result = Rdawn::ToolRegistry.execute('qloo_api', { interests: interests, city: city, preferences: preferences })
      
      # FIX: Manejar casos donde el resultado no es lo esperado
      if result.is_a?(Hash)
        return result
      else
        Rails.logger.error "Unexpected result format from qloo_api tool: #{result.class}"
        return { success: false, error: "Unexpected result format from Qloo API tool" }
      end
      
    rescue => e
      Rails.logger.error "Error calling qloo_api tool: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      return { success: false, error: "Tool execution failed: #{e.message}" }
    end
  end

  # Llama a la herramienta MapsApiTool para obtener información de lugares.
  #
  # @param query [String] La consulta de búsqueda para Google Places.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  def self.google_places(query:)
    begin
      result = Rdawn::ToolRegistry.execute('maps_api', { query: query })
      Rails.logger.info "Google Places API result for '#{query}': #{result.inspect}"
      
      # FIX: Manejar casos donde el resultado no es lo esperado
      if result.is_a?(Hash)
        return result
      else
        Rails.logger.error "Unexpected result format from maps_api tool: #{result.class}"
        return { success: false, error: "Unexpected result format from Google Places tool" }
      end
      
    rescue => e
      Rails.logger.error "Google Places API error for '#{query}': #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      return { success: false, error: "Tool execution failed: #{e.message}" }
    end
  end

def self.google_place_details(place_id:)
  return { success: false, error: 'No place_id provided' } unless place_id.present?
  
  api_key = ENV['GOOGLE_PLACES_API_KEY']
  fields = 'formatted_phone_number,international_phone_number,website,opening_hours,price_level,rating,user_ratings_total,formatted_address,geometry'
  
  url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=#{place_id}&fields=#{fields}&key=#{api_key}"
  
  begin
    response = HTTPX.get(url)
    
    if response.status == 200
      { success: true, data: JSON.parse(response.body.to_s) }
    else
      error_message = response.is_a?(HTTPX::ErrorResponse) ? response.error.message : response.body.to_s
      Rails.logger.error "Google Place Details API HTTP error: #{response.status} - #{error_message}"
      { success: false, error: "HTTP #{response.status}: #{error_message}" }
    end
  rescue => e
    Rails.logger.error "Google Place Details API exception: #{e.message}"
    { success: false, error: e.message }
  end
end
end
