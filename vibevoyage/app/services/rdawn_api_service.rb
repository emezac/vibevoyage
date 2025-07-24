# Servicio para encapsular llamadas a los APIs usando el workflow y herramientas de Rdawn

# frozen_string_literal: true

# frozen_string_literal: true

# Servicio para encapsular llamadas a las APIs externas a través de las herramientas de Rdawn.
# Proporciona una interfaz amigable y desacopla la lógica de negocio del registro de herramientas.
class RdawnApiService
  # Llama a la herramienta QlooApiTool para obtener recomendaciones culturales.
  #
  # @param interests [Array<String>] Una lista de intereses culturales.
  # @param city [String] La ciudad para la cual buscar recomendaciones.
  # @param preferences [Array<String>] (Opcional) Una lista de categorías para filtrar.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  #
  # --- CORRECCIÓN AQUÍ ---
  # Añadimos `preferences: []` a la firma del método para que acepte el nuevo argumento.
  def self.qloo_recommendations(interests:, city:, preferences: [])
    # Ahora pasamos los tres argumentos a la herramienta.
    Rdawn::ToolRegistry.execute('qloo_api', { interests: interests, city: city, preferences: preferences })
  end
  # --- FIN DE LA CORRECCIÓN ---

  # Llama a la herramienta MapsApiTool para obtener información de lugares.
  #
  # @param query [String] La consulta de búsqueda para Google Places.
  # @return [Hash] El resultado de la ejecución de la herramienta.
  def self.google_places(query:)
    Rdawn::ToolRegistry.execute('maps_api', { query: query })
  end
end
