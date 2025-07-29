# app/workflows/handlers/narrative_builder.rb
module WorkflowHandlers
  class NarrativeBuilder
    def self.call(input_data, workflow_variables)
      recommendations = input_data['recommendations'] || []
      user_vibe = workflow_variables['original_vibe'] || input_data['original_vibe']
      city = input_data['city'] || 'Unknown City'

      narrative = "<h2>Tu aventura personalizada en #{city}</h2>"
      narrative += "<p>Basado en tu vibe: <strong>#{user_vibe}</strong></p>"

      {
        success: true,
        narrative: narrative,
        city: city,
        recommendations: recommendations
      }
    end

    def build_experience(stop_data, index)
      {
        time: generate_time(index),
        title: stop_data['name'] || "Experiencia Cultural",
        description: stop_data['description'] || "Una experiencia única",
        location: stop_data['name'] || "Ubicación",
        area: extract_area(stop_data['address']),
        duration: stop_data['estimated_time'] || "1-2 horas",
        cultural_explanation: stop_data['cultural_reason'] || "Perfecta para tu vibe",
        vibe_match: rand(85..98),
        rating: "#{rand(4.2..4.9).round(1)}",
        image: generate_image_url(stop_data['name']),
        
        # ✅ IMPORTANTE: Asegurar que las coordenadas estén presentes
        latitude: stop_data['latitude'] || get_coordinates_for_place(stop_data['name'], @city)&.dig('lat'),
        longitude: stop_data['longitude'] || get_coordinates_for_place(stop_data['name'], @city)&.dig('lng'),
        formatted_address: stop_data['address'] || "#{stop_data['name']}, #{@city}",
        place_id: stop_data['place_id'] || generate_place_id(stop_data['name']),
        
        # 🆕 AGREGAR ESTOS CAMPOS FALTANTES
        phone: stop_data['phone'] || stop_data['formatted_phone_number'],
        website: stop_data['website'],
        formatted_phone_number: stop_data['formatted_phone_number'],
        international_phone_number: stop_data['international_phone_number']
      }
    end
 
  private

def get_coordinates_for_place(place_name, city)
  # Aquí deberías hacer una llamada a Google Places API si no tienes las coordenadas
  # Por ahora, coordenadas de ejemplo para Madrid:
  default_coordinates = {
    'Madrid' => { 'lat' => 40.4168, 'lng' => -3.7038 },
    'Barcelona' => { 'lat' => 41.3851, 'lng' => 2.1734 },
    'Mérida' => { 'lat' => 20.9674, 'lng' => -89.5926 }
  }
  
  default_coordinates[city] || { 'lat' => 40.4168, 'lng' => -3.7038 }
end
  end
end