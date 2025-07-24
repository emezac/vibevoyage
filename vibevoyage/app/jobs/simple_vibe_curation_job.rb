# app/jobs/simple_vibe_curation_job.rb

# Definir los handlers aquí mismo para evitar problemas de carga
module WorkflowHandlers
  class NarrativeBuilder
    def self.call(input_data, workflow_variables)
      puts "=== NarrativeBuilder ejecutándose ==="
      
      city = input_data[:city] || input_data['city'] || 'Unknown'
      original_vibe = input_data[:original_vibe] || input_data['original_vibe'] || ''
      
      narrative_html = <<~HTML
        <div class="narrative">
          <h2>🌟 Tu aventura en #{city}</h2>
          <p><strong>Tu vibe original:</strong> "#{original_vibe}"</p>
          
          <div class="city-info">
            <h3>📍 Destino: #{city}</h3>
            <p>Hemos creado una experiencia perfecta que combina lo mejor de la ciudad con tu estilo personal.</p>
          </div>
          
          <div class="recommendations">
            <h3>✨ Lo que te recomendamos</h3>
            <p>Una jornada cuidadosamente curada que conecta con tu esencia cultural.</p>
          </div>
        </div>
      HTML
      
      {
        narrative: narrative_html,
        city: city,
        original_vibe: original_vibe,
        success: true
      }
    end
  end

  class SaveItineraryHandler
    def self.call(input_data, workflow_variables)
      puts "=== SaveItineraryHandler ejecutándose ==="
      
      begin
        itinerary = Itinerary.create!(
          user_id: input_data[:user_id] || input_data['user_id'] || 1,
          description: input_data[:user_vibe] || input_data['user_vibe'],
          city: input_data[:city] || input_data['city'],
          narrative_html: input_data[:narrative_html] || input_data['narrative_html'],
          name: "Aventura en #{input_data[:city] || input_data['city']}",
          location: input_data[:city] || input_data['city']
        )
        
        puts "=== Itinerario creado con ID: #{itinerary.id} ==="
        
        {
          itinerary: itinerary,
          success: true,
          itinerary_id: itinerary.id
        }
      rescue => e
        puts "=== ERROR en SaveItineraryHandler: #{e.message} ==="
        { success: false, error: e.message }
      end
    end
  end
end

class SimpleVibeCurationJob < ApplicationJob
  queue_as :default

  def perform(user_id, user_vibe, session_id)
    puts "=== INICIANDO SimpleVibeCurationJob ==="
    puts "user_vibe: #{user_vibe}"
    puts "session_id: #{session_id}"
    
    begin
      # Paso 1: Enviar estado inicial de procesamiento
      send_processing_update(session_id, 15, "Analizando tu vibe cultural...")
      
      # Paso 2: Analizar el vibe
      city_data = analyze_vibe_with_openai(user_vibe)
      send_processing_update(session_id, 35, "Ciudad detectada: #{city_data[:city]}")
      
      # Paso 3: Buscar experiencias culturales
      send_processing_update(session_id, 55, "Consultando APIs de cultura...")
      sleep(1) # Simular tiempo de API
      
      # Paso 4: Crear narrative
      send_processing_update(session_id, 75, "Generando tu narrative personalizado...")
      narrative_html = build_narrative(city_data, user_vibe)
      
      # Paso 5: Guardar en la base de datos
      send_processing_update(session_id, 90, "Guardando tu aventura...")
      itinerary = save_itinerary(user_id, user_vibe, city_data, narrative_html)
      
      # Paso 6: Crear stops de ejemplo
      create_sample_stops(itinerary, city_data)
      
      # Paso 7: Enviar resultado final con el diseño hermoso
      send_processing_update(session_id, 100, "¡Tu aventura está lista!")
      send_final_result(session_id, itinerary, user_vibe, city_data)
      
      Rails.logger.info "SimpleVibeCurationJob completado para session_id: #{session_id}"
      
    rescue => e
      puts "=== ERROR en SimpleVibeCurationJob: #{e.message} ==="
      Rails.logger.error "SimpleVibeCurationJob falló: #{e.message}"
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "itinerary_channel:#{session_id}",
        target: "magic_canvas",
        partial: "itineraries/error_state",
        locals: { error_message: "No pudimos generar tu itinerario. Por favor, intenta de nuevo." }
      )
    end
  end

  private

  def send_processing_update(session_id, progress, message)
    puts "=== Enviando update: #{progress}% - #{message} ==="
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "itinerary_channel:#{session_id}",
      target: "magic_canvas", 
      partial: "itineraries/processing_state",
      locals: { 
        progress: progress,
        message: message,
        show_logs: true
      }
    )
    
    sleep(0.5) # Pequeña pausa para efecto visual
  end

  def send_final_result(session_id, itinerary, user_vibe, city_data)
    puts "=== Enviando resultado final con diseño UI ==="
    
    # Crear experiencias formateadas para el timeline
    experiences = create_timeline_experiences(itinerary, city_data)
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "itinerary_channel:#{session_id}",
      target: "magic_canvas",
      partial: "itineraries/timeline_result",
      locals: { 
        itinerary: itinerary,
        user_vibe: user_vibe,
        city: city_data[:city],
        experiences: experiences
      }
    )
  end

  def create_timeline_experiences(itinerary, city_data)
    city = city_data[:city]
    
    if city == 'Madrid'
      [
        {
          time: "09:00 AM",
          title: "Morning: A Cinematic Beginning", 
          description: "Comenzamos con una dosis de nostalgia y cafeína, en un lugar que respira historia cinematográfica.",
          location: "Café Doré & Filmoteca Española",
          image: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
          vibe_match: 95,
          duration: "2 hours",
          area: "Malasaña"
        },
        {
          time: "02:00 PM",
          title: "Afternoon: Pages and Serenity",
          description: "Una pausa contemplativa donde la literatura se encuentra con la naturaleza urbana.",
          location: "La Central Bookstore & Retiro Park", 
          image: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
          vibe_match: 92,
          duration: "3 hours",
          area: "Centro"
        },
        {
          time: "07:00 PM", 
          title: "Evening: Traditional Flavors",
          description: "El gran final: donde la gastronomía auténtica se convierte en el acto culminante de tu jornada cultural.",
          location: "Mercado de San Miguel",
          image: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
          vibe_match: 88,
          duration: "2.5 hours", 
          area: "La Latina"
        }
      ]
    else
      [
        {
          time: "10:00 AM",
          title: "Morning Discovery",
          description: "Comenzamos explorando el corazón cultural de #{city}.",
          location: "Centro Histórico de #{city}",
          image: "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
          vibe_match: 90,
          duration: "3 hours",
          area: "Centro"
        },
        {
          time: "06:00 PM",
          title: "Evening Experience", 
          description: "Culminamos con la experiencia gastronómica local más auténtica.",
          location: "Mercado Local de #{city}",
          image: "https://images.unsplash.com/photo-1544148103-0773bf10d330?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
          vibe_match: 85,
          duration: "2 hours",
          area: "Local"
        }
      ]
    end
  end

  # Resto de métodos existentes...
  def analyze_vibe_with_openai(user_vibe)
    puts "=== Analizando vibe con OpenAI ==="
    
    if user_vibe.downcase.include?('madrid')
      {
        city: 'Madrid',
        interests: ['tapas bar', 'cerveceria', 'cinema', 'books'],
        preferences: ['gastronomy', 'culture', 'relax']
      }
    elsif user_vibe.downcase.include?('barcelona')
      {
        city: 'Barcelona', 
        interests: ['tapas bar', 'art museum', 'architecture'],
        preferences: ['culture', 'gastronomy', 'art']
      }
    else
      {
        city: extract_city_from_text(user_vibe) || 'Madrid',
        interests: ['restaurant', 'cafe', 'culture'],
        preferences: ['gastronomy', 'culture']
      }
    end
  end

  def extract_city_from_text(text)
    cities = {
      'madrid' => 'Madrid', 'barcelona' => 'Barcelona', 'sevilla' => 'Sevilla',
      'valencia' => 'Valencia', 'paris' => 'Paris', 'london' => 'London',
      'rome' => 'Rome', 'roma' => 'Rome', 'new york' => 'New York',
      'nyc' => 'New York', 'mexico city' => 'Mexico City', 'cdmx' => 'Mexico City'
    }
    
    text_lower = text.downcase
    cities.each { |key, value| return value if text_lower.include?(key) }
    nil
  end

  def build_narrative(city_data, user_vibe)
    city = city_data[:city]
    interests = city_data[:interests]&.join(', ') || 'experiencias únicas'
    
    <<~HTML
      <div class="narrative">
        <h2>🌟 Tu aventura en #{city}</h2>
        <p><strong>Tu vibe original:</strong> "#{user_vibe}"</p>
        
        <div class="city-info">
          <h3>📍 Destino: #{city}</h3>
          <p>Hemos identificado que buscas una experiencia enfocada en: #{interests}</p>
        </div>
        
        <div class="recommendations">
          <h3>✨ Lo que te recomendamos</h3>
          <p>Basándome en tu vibe, #{city} es perfecto para ti. Te hemos preparado una experiencia única que combina lo mejor de la ciudad con tu estilo personal.</p>
        </div>
      </div>
    HTML
  end

  def save_itinerary(user_id, user_vibe, city_data, narrative_html)
    puts "=== Guardando itinerario en la base de datos ==="
    
    effective_user_id = user_id || 1
    
    attributes = {
      description: user_vibe,
      narrative_html: narrative_html,
      user_id: effective_user_id,
      city: city_data[:city],
      location: city_data[:city],
      name: "Aventura en #{city_data[:city]}",
      themes: city_data[:preferences]&.join(', ')
    }
    
    Itinerary.create!(attributes)
  end

  def create_sample_stops(itinerary, city_data)
    city = city_data[:city]
    
    if city == 'Madrid'
      stops_data = [
        {
          name: "Café Doré & Filmoteca",
          description: "Café histórico perfecto para amantes del cine",
          address: "Calle Santa Isabel, 3, Madrid"
        },
        {
          name: "La Central & Retiro",
          description: "Librería icónica y parque histórico",
          address: "Calle Postigo de San Martín, 8, Madrid"
        },
        {
          name: "Mercado de San Miguel",
          description: "Mercado gourmet con tapas auténticas",
          address: "Plaza de San Miguel, s/n, Madrid"
        }
      ]
    else
      stops_data = [
        {
          name: "Centro Histórico",
          description: "El corazón cultural de #{city}",
          address: "Centro de #{city}"
        },
        {
          name: "Mercado Local",
          description: "Experiencia gastronómica auténtica",
          address: "Mercado Principal, #{city}"
        }
      ]
    end
    
    stops_data.each do |stop_data|
      begin
        attributes = {}
        attributes[:name] = stop_data[:name] if ItineraryStop.column_names.include?('name')
        attributes[:description] = stop_data[:description] if ItineraryStop.column_names.include?('description')
        attributes[:address] = stop_data[:address] if ItineraryStop.column_names.include?('address')
        attributes[:latitude] = nil if ItineraryStop.column_names.include?('latitude')
        attributes[:longitude] = nil if ItineraryStop.column_names.include?('longitude')
        
        itinerary.itinerary_stops.create!(attributes)
        puts "✅ Stop creado: #{stop_data[:name]}"
      rescue => e
        puts "❌ Error creando stop: #{e.message}"
      end
    end
  end
end