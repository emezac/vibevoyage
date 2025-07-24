# app/jobs/process_vibe_job.rb
class ProcessVibeJob < ApplicationJob
  queue_as :default

  def perform(process_id, user_vibe)
    puts "=== INICIANDO ProcessVibeJob INTELIGENTE con LLM ==="
    puts "Process ID: #{process_id}"
    puts "User vibe: #{user_vibe}"
    
    # Obtener session_id del process_id
    session_id = extract_session_id(process_id) || process_id
    
    begin
      # Paso 1: Broadcast inicial y análisis con LLM
      broadcast_processing_state(session_id, 15, "Analizando tu vibe con IA...", user_vibe)
      update_status(process_id, 'analyzing', 'Analyzing your cultural essence...', 25)
      
      parsed_vibe = parse_vibe_with_rdawn(user_vibe, process_id)
      Rails.logger.info "--- Parsed Vibe from LLM: #{parsed_vibe.inspect}"
      
      # Paso 2: Broadcast y obtener recomendaciones de Qloo
      broadcast_processing_state(session_id, 35, "Consultando APIs culturales...", user_vibe, parsed_vibe)
      update_status(process_id, 'processing', 'Connecting with cultural databases...', 50)
      
      Rails.logger.info "--- Calling Qloo with: interests=#{parsed_vibe[:interests].inspect}, city=#{parsed_vibe[:city].inspect}, preferences=#{parsed_vibe[:preferences].inspect}"
      
      recommendations_result = RdawnApiService.qloo_recommendations(
        interests: parsed_vibe[:interests],
        city: parsed_vibe[:city],
        preferences: parsed_vibe[:preferences]
      )
      
      Rails.logger.info "--- Qloo API Result: #{recommendations_result.inspect}"
      
      unless recommendations_result[:success]
        error_msg = "Error fetching recommendations: #{recommendations_result[:error]}"
        broadcast_error(session_id, error_msg)
        update_status(process_id, 'failed', error_msg, 100)
        return
      end
      
      # Paso 3: Broadcast y generar itinerario
      broadcast_processing_state(session_id, 55, "Buscando lugares auténticos...", user_vibe, parsed_vibe)
      update_status(process_id, 'generating', 'Generating personalized narrative...', 75)
      
      final_itinerary = build_itinerary_from_qloo(recommendations_result[:data], parsed_vibe)
      
      # Paso 4: Broadcast construcción de timeline
      experiences = final_itinerary[:experiences] || []
      broadcast_timeline_building(session_id, experiences, parsed_vibe, user_vibe)
      
      # Paso 5: Guardar en base de datos
      itinerary = save_itinerary_to_db(user_vibe, parsed_vibe, final_itinerary)
      
      # Paso 6: Broadcast final
      broadcast_final_timeline(session_id, itinerary, experiences, parsed_vibe, user_vibe)
      
      # Actualizar cache final
      final_result = {
        status: 'complete',
        message: '¡Tu aventura está lista!',
        progress: 100,
        itinerary: format_final_itinerary(itinerary, experiences, parsed_vibe)
      }
      
      update_status(process_id, 'complete', 'Your adventure is ready!', 100, itinerary: final_result[:itinerary])
      
      Rails.logger.info "ProcessVibeJob completado para process_id: #{process_id}"
      
    rescue => e
      puts "=== ERROR en ProcessVibeJob: #{e.message} ==="
      Rails.logger.error "ProcessVibeJob falló: #{e.message}\n#{e.backtrace.join("\n")}"
      
      # Broadcast error
      broadcast_error(session_id, e.message)
      update_status(process_id, 'failed', "Error processing vibe: #{e.message}", 100)
    end
  end

  private

  def extract_session_id(process_id)
    # Extraer session_id del process_id si tiene formato "session_id_random"
    process_id.split('_').first
  end

  def broadcast_processing_state(session_id, progress, message, user_vibe, city_data = nil)
    puts "=== Broadcasting: #{progress}% - #{message} ==="
    
    ActionCable.server.broadcast("itinerary_channel:#{session_id}", {
      type: 'processing_update',
      progress: progress,
      message: message,
      user_vibe: user_vibe,
      city: city_data&.dig(:city),
      html: ApplicationController.render(
        partial: 'itineraries/live_processing_state',
        locals: { 
          progress: progress, 
          message: message, 
          user_vibe: user_vibe,
          city_data: city_data 
        }
      )
    })
    
    sleep(1)
  end

  def broadcast_timeline_building(session_id, experiences, city_data, user_vibe)
    puts "=== Broadcasting timeline construction ==="
    
    experiences.each_with_index do |experience, index|
      ActionCable.server.broadcast("itinerary_channel:#{session_id}", {
        type: 'timeline_step',
        step: index + 1,
        total_steps: experiences.size,
        experience: experience,
        html: ApplicationController.render(
          partial: 'itineraries/timeline_step',
          locals: { 
            experience: experience, 
            index: index,
            city_data: city_data 
          }
        )
      })
      
      sleep(2)
    end
  end

  def broadcast_final_timeline(session_id, itinerary, experiences, city_data, user_vibe)
    puts "=== Broadcasting final complete timeline ==="
    
    ActionCable.server.broadcast("itinerary_channel:#{session_id}", {
      type: 'final_timeline',
      itinerary_id: itinerary.id,
      html: ApplicationController.render(
        partial: 'itineraries/complete_timeline',
        locals: { 
          itinerary: itinerary,
          experiences: experiences, 
          city_data: city_data,
          user_vibe: user_vibe
        }
      )
    })
  end

  def broadcast_error(session_id, error_message)
    ActionCable.server.broadcast("itinerary_channel:#{session_id}", {
      type: 'error',
      message: error_message,
      html: ApplicationController.render(
        partial: 'itineraries/error_state',
        locals: { error_message: error_message }
      )
    })
  end

  def update_status(process_id, status, message, progress, itinerary: nil)
    status_data = { status: status, message: message, progress: progress, itinerary: itinerary }.compact
    Rails.cache.write("journey_#{process_id}", status_data, expires_in: 10.minutes)
  end

  def parse_vibe_with_rdawn(user_vibe, process_id)
    # Cargar el workflow manualmente si no está disponible
    unless defined?(::Workflows::VibeVoyageWorkflow)
      require_dependency Rails.root.join('app', 'workflows', 'workflows', 'vibe_voyage_workflow.rb')
    end
    
    vibe_parser_task_data = ::Workflows::VibeVoyageWorkflow.tasks.first
    parser_workflow = Rdawn::Workflow.new(workflow_id: "parser_#{process_id}", name: "Vibe Parser")
    
    prompt = vibe_parser_task_data[:prompt].gsub('{{input}}', user_vibe)
    parser_task = Rdawn::Task.new(
      task_id: vibe_parser_task_data[:id].to_s,
      name: "Parse User Vibe",
      is_llm_task: true,
      input_data: { prompt: prompt }
    )
    parser_workflow.add_task(parser_task)

    llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
    agent = Rdawn::Agent.new(workflow: parser_workflow, llm_interface: llm_interface)
    
    parsing_result = agent.run
    llm_response_json = parsing_result.tasks.values.first.output_data[:llm_response]
    
    extract_json_from_llm_response(llm_response_json).deep_symbolize_keys
  rescue NameError => e
    Rails.logger.error "Error loading Workflows module: #{e.message}"
    # Fallback: usar prompt directo sin workflow
    parse_vibe_directly_with_llm(user_vibe)
  end

  def parse_vibe_directly_with_llm(user_vibe)
    puts "=== Usando LLM directo para parsing ==="
    
    prompt = <<-PROMPT.strip
      Analyze the following text and extract key cultural entities. Your goal is to generate clean, useful JSON for a recommendation API.

      Rules:
      1. CITY IDENTIFICATION - Look for ANY mention of cities, including:
         - Direct mentions: "Mexico City", "Paris", "Tokyo", "New York"
         - Local references: "CDMX", "NYC", "SF", "LA"
         - Contextual clues: "in the capital of France", "Japanese capital"
         - Country mentions when city isn't specified: "Mexico" → "Mexico City", "France" → "Paris"
         - If NO location is mentioned at all, use "New York" as default
         - ALWAYS use the full, standardized city name in English (e.g., "Mexico City" not "CDMX")

      2. Extract ONLY specific place types or venue categories (e.g., 'art museum', 'coffee shop', 'cinema', 'tapas bar', 'bookstore', 'park'). 
         DO NOT include vague adjectives like 'quiet', 'bohemian', 'trendy'.

      3. Identify general experience themes (e.g., 'culture', 'gastronomy', 'nightlife', 'history', 'nature', 'art').

      4. Respond ONLY with valid JSON, no markdown or extra text.

      User Text: '#{user_vibe}'

      Example outputs:
      
      For "Exploring Mexico City's vibrant street art and authentic taquerias":
      {
        "city": "Mexico City",
        "interests": ["street art", "taqueria", "mural"],
        "preferences": ["art", "gastronomy", "culture"]
      }

      For "A day in Paris visiting museums and cafés":
      {
        "city": "Paris", 
        "interests": ["museum", "café"],
        "preferences": ["culture", "gastronomy"]
      }

      For "Tokyo ramen and temples":
      {
        "city": "Tokyo",
        "interests": ["ramen restaurant", "temple"],
        "preferences": ["gastronomy", "culture", "history"]
      }
    PROMPT

    llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
    
    # Crear un task simple para el LLM
    simple_task = Rdawn::Task.new(
      task_id: "direct_parse",
      name: "Direct Parse User Vibe",
      is_llm_task: true,
      input_data: { prompt: prompt }
    )
    
    # Crear workflow simple
    simple_workflow = Rdawn::Workflow.new(workflow_id: "direct_parser", name: "Direct Vibe Parser")
    simple_workflow.add_task(simple_task)
    
    agent = Rdawn::Agent.new(workflow: simple_workflow, llm_interface: llm_interface)
    result = agent.run
    
    llm_response = result.tasks.values.first.output_data[:llm_response]
    extract_json_from_llm_response(llm_response).deep_symbolize_keys
  end

  def extract_json_from_llm_response(response_text)
    cleaned_text = response_text.strip.gsub(/^```json\n?/, '').gsub(/\n?```$/, '')
    JSON.parse(cleaned_text)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse cleaned LLM response: #{cleaned_text}"
    raise e
  end

  def build_itinerary_from_qloo(qloo_data, parsed_vibe)
    if qloo_data.nil? || qloo_data.dig('results', 'entities').blank?
      Rails.logger.warn "--- Qloo returned no entities. Creating fallback experiences."
      return create_fallback_itinerary(parsed_vibe)
    end

    experiences = (qloo_data.dig('results', 'entities') || []).first(3).map.with_index do |rec, index|
      {
        time: ["09:00 AM", "02:00 PM", "07:00 PM"][index] || "#{10 + index}:00 AM",
        title: rec['name'] || "Experience #{index + 1}",
        location: rec['name'] || "Location #{index + 1}",
        description: rec.dig('properties', 'summary') || 'A fascinating cultural experience.',
        duration: "#{rand(1..3)} hours",
        area: rec.dig('properties', 'geocode', 'name') || extract_area_from_city(parsed_vibe[:city]),
        vibe_match: [(rec['popularity'].to_f * 100).round, 85].max,
        rating: rec.dig('properties', 'business_rating') || rand(4.0..5.0).round(1),
        image: rec.dig('properties', 'images', 0, 'url') || get_default_image(index),
        api_data: rec
      }
    end

    {
      title: "Your Curated Adventure in #{parsed_vibe[:city] || 'Your Destination'}",
      experiences: experiences
    }
  end

  def create_fallback_itinerary(parsed_vibe)
    city = parsed_vibe[:city] || 'Your Destination'
    interests = parsed_vibe[:interests] || ['cultural experiences']
    
    experiences = [
      {
        time: "10:00 AM",
        title: "Morning Discovery",
        location: "Local Cultural Center",
        description: "Start your day exploring the cultural heart of #{city}.",
        duration: "2 hours",
        area: "City Center",
        vibe_match: 85,
        rating: 4.2,
        image: get_default_image(0),
        api_data: {}
      },
      {
        time: "02:00 PM",
        title: "Afternoon Experience",
        location: "Traditional Restaurant",
        description: "Enjoy authentic local cuisine and atmosphere.",
        duration: "2 hours",
        area: "Historic District",
        vibe_match: 88,
        rating: 4.4,
        image: get_default_image(1),
        api_data: {}
      },
      {
        time: "07:00 PM",
        title: "Evening Adventure",
        location: "Popular Local Spot",
        description: "End your day at a favorite local gathering place.",
        duration: "3 hours",
        area: "Entertainment District",
        vibe_match: 82,
        rating: 4.1,
        image: get_default_image(2),
        api_data: {}
      }
    ]

    {
      title: "Your Adventure in #{city}",
      experiences: experiences
    }
  end

  def save_itinerary_to_db(user_vibe, parsed_vibe, final_itinerary)
    puts "=== Guardando itinerario en la base de datos ==="
    
    city = parsed_vibe[:city] || 'Unknown City'
    interests = parsed_vibe[:interests]&.join(', ') || 'various interests'
    preferences = parsed_vibe[:preferences]&.join(', ') || 'various preferences'
    
    narrative_html = build_narrative_html(parsed_vibe, user_vibe, final_itinerary[:experiences])
    
    itinerary = Itinerary.create!(
      user_id: 1, # Usuario por defecto
      description: user_vibe,
      city: city,
      location: city,
      name: "Adventure in #{city}",
      narrative_html: narrative_html,
      themes: preferences
    )
    
    # Crear stops basados en experiencias
    final_itinerary[:experiences].each_with_index do |exp, index|
      begin
        attributes = {
          name: exp[:location],
          description: exp[:description], 
          address: "#{exp[:area]}, #{city}"
        }
        
        # Solo agregar columnas que existen
        column_names = ItineraryStop.column_names
        attributes[:position] = index + 1 if column_names.include?('position')
        attributes[:latitude] = nil if column_names.include?('latitude')
        attributes[:longitude] = nil if column_names.include?('longitude')
        
        stop = itinerary.itinerary_stops.create!(attributes)
        puts "✅ Stop creado: #{exp[:location]} (ID: #{stop.id})"
        
      rescue => e
        puts "❌ Error creando stop: #{e.message}"
      end
    end
    
    puts "✅ Itinerario guardado con ID: #{itinerary.id}"
    itinerary
  end

  def build_narrative_html(parsed_vibe, user_vibe, experiences)
    city = parsed_vibe[:city]
    interests = parsed_vibe[:interests]&.join(', ')
    
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
          <p>Basándome en tu vibe y datos de APIs culturales reales, #{city} es perfecto para ti. Hemos curado #{experiences.size} experiencias únicas.</p>
        </div>
      </div>
    HTML
  end

  def format_final_itinerary(itinerary, experiences, parsed_vibe)
    {
      id: itinerary.id,
      title: "Your Adventure in #{parsed_vibe[:city]}",
      city: parsed_vibe[:city],
      experiences: experiences,
      narrative_html: itinerary.narrative_html,
      created_at: itinerary.created_at
    }
  end

  def extract_area_from_city(city)
    return "Centro" unless city
    
    # Areas genéricas por ciudad
    city_areas = {
      'Mexico City' => 'Centro Histórico',
      'Madrid' => 'Centro',
      'New York' => 'Manhattan',
      'Paris' => 'Marais',
      'London' => 'Westminster',
      'Tokyo' => 'Shibuya',
      'Monterrey' => 'San Pedro'
    }
    
    city_areas[city] || 'City Center'
  end

  def get_default_image(index)
    images = [
      "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3", 
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
    ]
    images[index] || images.first
  end
end