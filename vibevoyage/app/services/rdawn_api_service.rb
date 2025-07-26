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
end
