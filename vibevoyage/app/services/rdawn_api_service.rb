class RdawnApiService
  # Llama a la herramienta QlooApiTool para obtener recomendaciones culturales.
  #
  # @param interests [Array<String>] Una lista de intereses culturales.
  # @param city [String] La ciudad para la cual buscar recomendaciones.
  # @param preferences [Array<String>] (Opcional) Una lista de categorías para filtrar.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  def self.qloo_recommendations(interests:, city:, preferences: [])
    # Pasamos los tres argumentos a la herramienta.
    Rdawn::ToolRegistry.execute('qloo_api', { interests: interests, city: city, preferences: preferences })
  end

  # Llama a la herramienta MapsApiTool para obtener información de lugares.
  #
  # @param query [String] La consulta de búsqueda para Google Places.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  def self.google_places(query:)
    begin
      result = Rdawn::ToolRegistry.execute('maps_api', { query: query })
      Rails.logger.info "Google Places API result for '#{query}': #{result.inspect}"
      result
    rescue => e
      Rails.logger.error "Google Places API error for '#{query}': #{e.message}"
      { success: false, error: e.message }
    end
  end
end