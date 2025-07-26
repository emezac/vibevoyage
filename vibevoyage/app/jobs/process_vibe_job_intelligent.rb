# app/jobs/process_vibe_job_intelligent.rb
class ProcessVibeJobIntelligent < ApplicationJob
  queue_as :default

def perform(process_id, user_vibe)
  puts "=== INICIANDO ProcessVibeJobIntelligent ==="
  puts "Process ID: #{process_id}"
  puts "User vibe: #{user_vibe}"
  
  begin
    # Paso 1: Análisis con LLM (25%)
    update_status(process_id, 'analyzing', 'Analizando tu esencia cultural...', 25)
    
    parsed_vibe = parse_vibe_with_rdawn(user_vibe, process_id)
    Rails.logger.info "--- Parsed Vibe from LLM: #{parsed_vibe.inspect}"
    
    # Paso 2: Consulta a Qloo API (50%)
    update_status(process_id, 'processing', 'Conectando con bases de datos culturales...', 50)
    
    Rails.logger.info "--- Calling Qloo with: interests=#{parsed_vibe[:interests].inspect}, city=#{parsed_vibe[:city].inspect}, preferences=#{parsed_vibe[:preferences].inspect}"
    
    recommendations_result = RdawnApiService.qloo_recommendations(
      interests: parsed_vibe[:interests],
      city: parsed_vibe[:city],
      preferences: parsed_vibe[:preferences]
    )
    
    Rails.logger.info "--- Qloo API Result: #{recommendations_result.inspect}"
    
    unless recommendations_result[:success]
      error_msg = "Error fetching recommendations: #{recommendations_result[:error]}"
      update_status(process_id, 'failed', error_msg, 100)
      return
    end
    
    # Paso 3: Curación inteligente con explicaciones (75%)
    update_status(process_id, 'curating', 'Curando experiencias con contexto cultural...', 75)
    
    curated_experiences = curate_experiences_with_explanations(
      parsed_vibe, 
      recommendations_result[:data]
    )
    
    # Paso 4: Construir narrativa final (90%)
    update_status(process_id, 'finalizing', 'Construyendo tu narrativa personalizada...', 90)
    
    narrative = build_intelligent_narrative(parsed_vibe, user_vibe, curated_experiences)
    
    # Paso 5: Guardar en base de datos con explicaciones culturales
    itinerary = save_intelligent_itinerary(user_vibe, parsed_vibe, narrative, curated_experiences)
    
    # *** RESULTADO FINAL ACTUALIZADO CON TODOS LOS CAMPOS ***
    final_result = {
      status: 'complete',
      message: '¡Tu aventura cultural está lista!',
      progress: 100,
      itinerary: {
        id: itinerary.id,
        title: "Tu Aventura en #{parsed_vibe[:city]}",
        city: parsed_vibe[:city],
        narrative_html: narrative,
        experiences: curated_experiences.map.with_index do |exp, index|
          {
            # *** CAMPOS BÁSICOS ***
            id: itinerary.itinerary_stops[index]&.id,
            time: exp[:time],
            title: exp[:title],
            location: exp[:location],
            description: exp[:description],
            cultural_explanation: exp[:cultural_explanation],
            duration: exp[:duration],
            area: exp[:area],
            vibe_match: exp[:vibe_match],
            rating: exp[:rating],
            image: exp[:image],
            
            # *** DATOS PRINCIPALES DE QLOO ***
            qloo_keywords: exp[:qloo_keywords] || [],
            qloo_entity_id: exp[:qloo_entity_id],
            qloo_popularity: exp[:qloo_popularity],
            why_chosen: exp[:why_chosen],
            
            # *** INFORMACIÓN DE CONTACTO Y UBICACIÓN ***
            website: exp[:website],
            phone: exp[:phone],
            address: exp[:address],
            latitude: exp[:latitude],
            longitude: exp[:longitude],
            google_maps_url: exp[:google_maps_url],
            directions_url: exp[:directions_url],
            
            # *** INFORMACIÓN OPERATIVA ***
            hours: exp[:hours],
            price_level: exp[:price_level],
            price_range: exp[:price_range],
            
            # *** CATEGORÍAS Y CARACTERÍSTICAS ***
            tags: exp[:tags] || [],
            categories: exp[:categories] || [],
            amenities: exp[:amenities] || [],
            accessibility: exp[:accessibility],
            family_friendly: exp[:family_friendly],
            
            # *** INFORMACIÓN ADICIONAL ***
            booking_info: exp[:booking_info]
          }.compact  # Remove nil values
        end
      }
    }
    
    update_status(process_id, 'complete', '¡Tu aventura está lista!', 100, itinerary: final_result[:itinerary])
    
    Rails.logger.info "ProcessVibeJobIntelligent completado para process_id: #{process_id}"
    Rails.logger.info "--- Total campos por experiencia: #{final_result[:itinerary][:experiences].first&.keys&.size || 0}"
    Rails.logger.info "--- Experiencias con coordenadas: #{final_result[:itinerary][:experiences].count { |e| e[:latitude] && e[:longitude] }}"
    Rails.logger.info "--- Experiencias con website: #{final_result[:itinerary][:experiences].count { |e| e[:website] }}"
    
  rescue => e
    puts "=== ERROR en ProcessVibeJobIntelligent: #{e.message} ==="
    Rails.logger.error "ProcessVibeJobIntelligent falló: #{e.message}\n#{e.backtrace.join("\n")}"
    
    # *** MEJORAR EL FALLBACK ***
    begin
      puts "=== Attempting fallback response ==="
      update_status(process_id, 'processing', 'Creando experiencia de fallback...', 75)
      
      # Parse vibe with simpler method
      parsed_vibe = simple_vibe_parsing(user_vibe)
      
      # Create fallback experiences
      fallback_experiences = create_comprehensive_fallback(parsed_vibe)
      
      # Create simple narrative
      fallback_narrative = create_fallback_narrative(parsed_vibe, user_vibe)
      
      # Save fallback itinerary
      fallback_itinerary = save_fallback_itinerary(user_vibe, parsed_vibe, fallback_narrative, fallback_experiences)
      
      # Create final result with same enhanced structure
      final_result = {
        status: 'complete',
        message: '¡Tu aventura está lista! (Modo offline)',
        progress: 100,
        itinerary: {
          id: fallback_itinerary.id,
          title: "Tu Aventura en #{parsed_vibe[:city]}",
          city: parsed_vibe[:city],
          narrative_html: fallback_narrative,
          experiences: fallback_experiences.map.with_index do |exp, index|
            {
              # Same enhanced structure as the main path
              id: fallback_itinerary.itinerary_stops[index]&.id,
              time: exp[:time],
              title: exp[:title],
              location: exp[:location],
              description: exp[:description],
              cultural_explanation: exp[:cultural_explanation],
              duration: exp[:duration],
              area: exp[:area],
              vibe_match: exp[:vibe_match],
              rating: exp[:rating],
              image: exp[:image],
              qloo_keywords: exp[:qloo_keywords] || [],
              qloo_entity_id: nil,
              qloo_popularity: nil,
              why_chosen: exp[:why_chosen],
              website: exp[:website],
              phone: exp[:phone],
              address: exp[:address],
              latitude: exp[:latitude],
              longitude: exp[:longitude],
              google_maps_url: exp[:latitude] && exp[:longitude] ? 
                "https://www.google.com/maps/search/?api=1&query=#{exp[:latitude]},#{exp[:longitude]}" : nil,
              directions_url: exp[:latitude] && exp[:longitude] ? 
                "https://www.google.com/maps/dir/?api=1&destination=#{exp[:latitude]},#{exp[:longitude]}" : nil,
              hours: exp[:hours],
              price_level: exp[:price_level],
              price_range: exp[:price_range],
              tags: exp[:tags] || [],
              categories: [],
              amenities: [],
              accessibility: nil,
              family_friendly: nil,
              booking_info: nil
            }.compact
          end
        }
      }
      
      update_status(process_id, 'complete', '¡Tu aventura está lista!', 100, itinerary: final_result[:itinerary])
      puts "✅ Fallback response created successfully with enhanced data structure"
      
    rescue => fallback_error
      puts "=== FALLBACK ALSO FAILED: #{fallback_error.message} ==="
      update_status(process_id, 'failed', "Error procesando tu vibe: #{e.message}", 100)
    end
  end
end

  private

  def update_status(process_id, status, message, progress, itinerary: nil)
    status_data = { 
      status: status, 
      message: message, 
      progress: progress, 
      itinerary: itinerary 
    }.compact
    
    Rails.cache.write("journey_#{process_id}", status_data, expires_in: 15.minutes)
    puts "=== Status Update: #{progress}% - #{message} ==="
  end

  def parse_vibe_with_rdawn(user_vibe, process_id)
    begin
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
      
      return extract_json_from_llm_response(llm_response_json).deep_symbolize_keys
      
    rescue => e
      Rails.logger.error "Error en workflow parsing: #{e.message}"
      return parse_vibe_directly_with_llm(user_vibe)
    end
  end

  def parse_vibe_directly_with_llm(user_vibe)
    puts "=== Usando LLM directo para parsing ==="
    
    prompt = <<-PROMPT.strip
      Analyze this text and extract cultural entities for a recommendation API.

      Rules:
      1. CITY: Look for any city mention or country reference
      2. INTERESTS: Extract specific venue types (steakhouse, wine bar, tapas bar, etc.)
      3. PREFERENCES: General themes (culture, gastronomy, nightlife, etc.)
      4. Return ONLY valid JSON

      Text: '#{user_vibe}'

      Example: {"city": "Toronto", "interests": ["steakhouse", "wine bar"], "preferences": ["gastronomy", "luxury"]}
    PROMPT

    llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
    simple_task = Rdawn::Task.new(
      task_id: "direct_parse",
      name: "Direct Parse User Vibe",
      is_llm_task: true,
      input_data: { prompt: prompt }
    )
    
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
    Rails.logger.error "Failed to parse LLM response: #{cleaned_text}"
    raise e
  end

  # *** FUNCIÓN HÍBRIDA: Usar coordenadas de Qloo + Google Places para enriquecer ***
  def fetch_google_places_data(parsed_vibe, qloo_data)
    city = parsed_vibe[:city]
    interests = parsed_vibe[:interests]
    
    puts "=== PROCESANDO DATOS DE QLOO CON ENRIQUECIMIENTO OPCIONAL ==="
    puts "Ciudad: #{city}"
    puts "Intereses: #{interests.inspect}"
    puts "Qloo data present: #{qloo_data&.dig('results', 'entities')&.any? || false}"
    
    places_results = []
    
    # Si tenemos datos de Qloo, usar esos datos como base
    if qloo_data && qloo_data.dig('results', 'entities')&.any?
      puts "=== USANDO COORDENADAS DE QLOO + DATOS DE GOOGLE PLACES ==="
      qloo_entities = qloo_data.dig('results', 'entities').first(3)
      
      qloo_entities.each_with_index do |entity, index|
        place_name = entity['name']
        qloo_location = entity['location']
        qloo_address = entity.dig('properties', 'address')
        
        puts "--- Procesando entidad #{index + 1}: #{place_name}"
        puts "--- Coordenadas de Qloo: #{qloo_location.inspect}"
        
        # Usar coordenadas de Qloo como fuente principal
        if qloo_location && qloo_location['lat'] && qloo_location['lon']
          coordinates = {
            'lat' => qloo_location['lat'].to_f,
            'lng' => qloo_location['lon'].to_f
          }
          
          # Intentar enriquecer con datos de Google Places (opcional)
          google_data = try_enrich_with_google_places(place_name, city, coordinates)
          
          # Si Google Places no funciona, usar datos de Qloo
          final_google_data = google_data || create_google_data_from_qloo(entity, coordinates)
          
          puts "--- ✅ USANDO COORDS DE QLOO: #{place_name} - Coords: #{coordinates.inspect}"
          
          places_results << {
            name: place_name,
            google_data: final_google_data,
            qloo_entity: entity
          }
        else
          puts "--- ❌ No hay coordenadas en Qloo para: #{place_name}, buscando en Google..."
          
          # Solo buscar en Google Places si Qloo no tiene coordenadas
          google_result = search_in_google_places_fallback(place_name, city)
          
          places_results << {
            name: place_name,
            google_data: google_result,
            qloo_entity: entity
          }
        end
      end
    else
      # Fallback: buscar lugares genéricos cuando no hay datos de Qloo
      puts "=== NO HAY DATOS DE QLOO - USANDO BÚSQUEDA GENÉRICA ==="
      generic_queries = build_fallback_queries(interests, city)
      
      generic_queries.each_with_index do |query, index|
        puts "--- Generic Query #{index + 1}: #{query}"
        
        begin
          google_result = RdawnApiService.google_places(query: query)
          
          if google_result[:success] && google_result[:data]&.dig('results')&.any?
            best_place = find_best_matching_place(google_result[:data]['results'], city)
            
            if best_place
              coordinates = best_place.dig('geometry', 'location')
              puts "--- ✅ LUGAR GENÉRICO ENCONTRADO: #{best_place['name']} - Coords: #{coordinates.inspect}"
              
              places_results << {
                name: best_place['name'],
                google_data: best_place,
                qloo_entity: nil
              }
            end
          end
        rescue => e
          puts "--- ❌ ERROR en búsqueda genérica: #{e.message}"
        end
      end
    end
    
    # Si no encontramos nada, crear fallback con LLM
    if places_results.empty? || places_results.all? { |r| r[:google_data].nil? }
      puts "=== CREANDO FALLBACK CON LLM ==="
      fallback_place = create_fallback_place_with_coordinates(city, interests.first)
      places_results << fallback_place if fallback_place
    end
    
    puts "=== RESULTADO FINAL ==="
    puts "Total lugares encontrados: #{places_results.size}"
    places_results.each_with_index do |result, index|
      coords = result[:google_data]&.dig('geometry', 'location')
      puts "#{index + 1}. #{result[:name]} - Coords: #{coords&.inspect || 'SIN COORDENADAS'}"
    end
    
    Rails.logger.info "--- Total places found: #{places_results.size}"
    places_results
  end

  # Función para crear datos de Google Places desde Qloo
  def create_google_data_from_qloo(entity, coordinates)
    {
      'name' => entity['name'],
      'formatted_address' => entity.dig('properties', 'address') || "#{entity['name']}",
      'geometry' => {
        'location' => coordinates
      },
      'place_id' => entity['entity_id'] || "qloo_#{SecureRandom.hex(4)}",
      'rating' => entity.dig('properties', 'business_rating')&.to_f || 4.0,
      'types' => extract_types_from_qloo_entity(entity)
    }
  end

  # Función opcional para enriquecer con Google Places (puede fallar)
  def try_enrich_with_google_places(place_name, city, qloo_coordinates)
    puts "--- Intentando enriquecer #{place_name} con Google Places..."
    
    begin
      query = "#{place_name} #{city}"
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        results = google_result[:data]['results']
        
        # Buscar resultado que esté cerca de las coordenadas de Qloo
        best_match = results.find do |place|
          google_coords = place.dig('geometry', 'location')
          next false unless google_coords
          
          # Verificar si están cerca (dentro de ~1km)
          distance = calculate_distance(
            qloo_coordinates['lat'], qloo_coordinates['lng'],
            google_coords['lat'], google_coords['lng']
          )
          
          distance < 1.0 # Menos de 1km de diferencia
        end
        
        if best_match
          # Usar coordenadas de Qloo pero otros datos de Google
          best_match['geometry']['location'] = qloo_coordinates
          puts "--- ✅ Enriquecido con Google Places: #{best_match['name']}"
          return best_match
        end
      end
      
      puts "--- No se pudo enriquecer con Google Places"
      return nil
      
    rescue => e
      puts "--- Error enriqueciendo con Google Places: #{e.message}"
      return nil
    end
  end

  # Función para calcular distancia entre coordenadas
  def calculate_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rlat1 = lat1 * rad_per_deg
    rlat2 = lat2 * rad_per_deg
    dlat = rlat2 - rlat1
    dlon = (lon2 - lon1) * rad_per_deg
    
    a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlon/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    6371 * c # Distancia en kilómetros
  end

  # Función para extraer tipos de lugar basándose en los tags de Qloo
  def extract_types_from_qloo_entity(entity)
    tags = entity['tags'] || []
    types = []
    
    tags.each do |tag|
      tag_name = tag['name']&.downcase
      case tag_name
      when /hotel|hostel/
        types << 'lodging'
      when /restaurant/
        types << 'restaurant'
      when /bar/
        types << 'bar'
      when /museum/
        types << 'museum'
      when /park/
        types << 'park'
      end
    end
    
    types << 'point_of_interest' if types.empty?
    types << 'establishment'
    
    types.uniq
  end

  # Fallback solo cuando Qloo no tiene coordenadas
  def search_in_google_places_fallback(place_name, city)
    query = "#{place_name} #{city}"
    puts "--- Fallback Google search: #{query}"
    
    begin
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        best_place = find_best_matching_place(google_result[:data]['results'], city, place_name)
        puts "--- ✅ Fallback encontrado: #{best_place['name']}" if best_place
        return best_place
      else
        puts "--- ❌ No se encontró en Google Places: #{query}"
        return nil
      end
    rescue => e
      puts "--- ❌ Error en fallback de Google: #{e.message}"
      return nil
    end
  end

  # Nueva función para crear un lugar de fallback usando LLM para coordenadas
  def create_fallback_place_with_coordinates(city, interest)
    prompt = <<-PROMPT.strip
      Necesito las coordenadas aproximadas del centro de la ciudad para crear un marcador de fallback.
      
      Ciudad: #{city}
      Interés del usuario: #{interest}
      
      Proporciona:
      1. Latitud y longitud del centro histórico/turístico principal de #{city}
      2. Un nombre apropiado para el lugar (ej: "Centro Cultural de [Ciudad]", "Plaza Principal de [Ciudad]")
      
      Responde en formato JSON:
      {
        "latitude": 00.0000,
        "longitude": 00.0000,
        "place_name": "Nombre del lugar"
      }
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "fallback_coords_#{SecureRandom.hex(4)}",
        name: "Generate Fallback Coordinates",
        is_llm_task: true,
        input_data: { prompt: prompt }
      )
      
      workflow = Rdawn::Workflow.new(workflow_id: "coords_generator", name: "Coordinates Generator")
      workflow.add_task(task)
      
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
      result = agent.run
      
      llm_response = result.tasks.values.first.output_data[:llm_response]
      coords_data = extract_json_from_llm_response(llm_response)
      
      latitude = coords_data['latitude'].to_f
      longitude = coords_data['longitude'].to_f
      place_name = coords_data['place_name'] || "Centro Cultural de #{city}"
      
      puts "--- ✅ CREANDO FALLBACK con LLM: #{place_name} - Coords: {lat: #{latitude}, lng: #{longitude}}"
      
      {
        name: place_name,
        google_data: {
          'name' => place_name,
          'formatted_address' => "Centro, #{city}",
          'geometry' => {
            'location' => { 'lat' => latitude, 'lng' => longitude }
          },
          'place_id' => "fallback_#{city.downcase.gsub(' ', '_')}",
          'rating' => 4.2
        },
        qloo_entity: nil
      }
      
    rescue => e
      puts "--- Error generando fallback con LLM: #{e.message}"
      Rails.logger.error "--- Error generating fallback coordinates: #{e.message}"
      
      # Fallback del fallback - coordenadas muy básicas
      {
        name: "Centro de #{city}",
        google_data: {
          'name' => "Centro de #{city}",
          'formatted_address' => "Centro, #{city}",
          'geometry' => {
            'location' => { 'lat' => 0.0, 'lng' => 0.0 }
          },
          'place_id' => "emergency_fallback",
          'rating' => 4.0
        },
        qloo_entity: nil
      }
    end
  end

  def build_fallback_queries(interests, city)
    queries = []
    
    # Construir búsquedas más específicas basadas en los intereses
    interests.each do |interest|
      case interest
      when /soup|restaurant|food/
        queries << "restaurantes #{city}"
        queries << "comida tradicional #{city}"
        queries << "restaurante auténtico #{city}"
      when /tequila|mezcal|bar|craft beer/
        queries << "bar #{city}"
        queries << "cantina #{city}"
        queries << "cerveza artesanal #{city}"
      when /art|museum/
        queries << "museo #{city}"
        queries << "galería de arte #{city}"
        queries << "museo de arte #{city}"
      when /cinema|movie/
        queries << "cine #{city}"
        queries << "cinema #{city}"
        queries << "teatro #{city}"
      when /culture/
        queries << "centro cultural #{city}"
        queries << "sitio histórico #{city}"
        queries << "atracción cultural #{city}"
      else
        queries << "#{interest} #{city}"
      end
    end
    
    # Si no hay queries específicas, usar términos genéricos garantizados
    if queries.empty?
      queries = [
        "restaurantes #{city}",
        "atracciones turísticas #{city}",
        "lugares de interés #{city}"
      ]
    end
    
    # Asegurar que siempre tengamos al menos 3 queries diferentes
    while queries.size < 3
      queries += [
        "centro histórico #{city}",
        "plaza principal #{city}",
        "catedral #{city}",
        "parque #{city}",
        "mercado #{city}"
      ]
    end
    
    puts "--- Queries generadas: #{queries.uniq.first(3).inspect}"
    queries.uniq.first(3)
  end

  def build_fallback_queries(interests, city)
    queries = []
    
    # Construir búsquedas más específicas basadas en los intereses
    interests.each do |interest|
      case interest
      when /soup|restaurant|food/
        queries << "restaurantes #{city}"
        queries << "comida tradicional #{city}"
        queries << "restaurante auténtico #{city}"
      when /tequila|mezcal|bar|craft beer/
        queries << "bar #{city}"
        queries << "cantina #{city}"
        queries << "cerveza artesanal #{city}"
      when /art|museum/
        queries << "museo #{city}"
        queries << "galería de arte #{city}"
        queries << "museo de arte #{city}"
      when /cinema|movie/
        queries << "cine #{city}"
        queries << "cinema #{city}"
        queries << "teatro #{city}"
      when /culture/
        queries << "centro cultural #{city}"
        queries << "sitio histórico #{city}"
        queries << "atracción cultural #{city}"
      else
        queries << "#{interest} #{city}"
      end
    end
    
    # Si no hay queries específicas, usar términos genéricos garantizados
    if queries.empty?
      queries = [
        "restaurantes #{city}",
        "atracciones turísticas #{city}",
        "lugares de interés #{city}"
      ]
    end
    
    # Asegurar que siempre tengamos al menos 3 queries diferentes
    while queries.size < 3
      queries += [
        "centro histórico #{city}",
        "plaza principal #{city}",
        "catedral #{city}",
        "parque #{city}",
        "mercado #{city}"
      ]
    end
    
    puts "--- Queries generadas: #{queries.uniq.first(3).inspect}"
    queries.uniq.first(3)
  end

  # Nueva función para encontrar el mejor resultado usando LLM
  def find_best_matching_place(results, target_city, place_name = nil)
    return nil if results.empty?
    
    puts "--- Evaluating #{results.size} results for city: #{target_city} and place: #{place_name}"
    
    # Si solo hay un resultado, usarlo directamente
    if results.size == 1
      puts "--- Only one result, using it: #{results.first['name']}"
      return results.first
    end
    
    # Usar LLM para encontrar el mejor match
    places_data = results.map.with_index do |place, index|
      {
        index: index,
        name: place['name'],
        address: place['formatted_address'],
        rating: place['rating'],
        types: place['types']&.join(', ')
      }
    end
    
    prompt = <<-PROMPT.strip
      Necesito que selecciones el mejor lugar de esta lista basándote en los criterios dados.

      CRITERIOS DE BÚSQUEDA:
      - Ciudad objetivo: #{target_city}
      - Lugar específico buscado: #{place_name || 'cualquier lugar relevante'}

      OPCIONES DISPONIBLES:
      #{places_data.map { |p| "#{p[:index]}. #{p[:name]} - #{p[:address]} (Rating: #{p[:rating]} | Tipos: #{p[:types]})" }.join("\n")}

      INSTRUCCIONES:
      1. Selecciona el lugar que mejor coincida con la ciudad objetivo "#{target_city}"
      2. Si hay un nombre específico "#{place_name}", prioriza lugares con nombres similares
      3. Considera la ubicación geográfica (la dirección debe estar en o cerca de #{target_city})
      4. En caso de empate, prefiere el lugar con mejor rating
      5. Responde SOLO con el número del índice (0, 1, 2, etc.)

      RESPUESTA (solo el número):
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "match_place_#{SecureRandom.hex(4)}",
        name: "Find Best Matching Place",
        is_llm_task: true,
        input_data: { prompt: prompt }
      )
      
      workflow = Rdawn::Workflow.new(workflow_id: "place_matcher", name: "Place Matcher")
      workflow.add_task(task)
      
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
      result = agent.run
      
      llm_response = result.tasks.values.first.output_data[:llm_response].strip
      selected_index = llm_response.to_i
      
      if selected_index >= 0 && selected_index < results.size
        selected_place = results[selected_index]
        puts "--- LLM selected index #{selected_index}: #{selected_place['name']}"
        return selected_place
      else
        puts "--- LLM returned invalid index #{selected_index}, using first result"
        return results.first
      end
      
    rescue => e
      puts "--- Error using LLM for place matching: #{e.message}"
      Rails.logger.error "--- Error using LLM for place matching: #{e.message}"
      
      # Fallback: usar el primer resultado
      puts "--- Using first result as fallback: #{results.first['name']}"
      return results.first
    end
  end

  def extract_area_from_google_data(google_data, city)
    return "Centro" unless google_data&.dig('formatted_address')
    
    address = google_data['formatted_address']
    
    prompt = <<-PROMPT.strip
      Extrae el nombre del área, barrio o distrito de esta dirección:
      
      Dirección: "#{address}"
      Ciudad: #{city}
      
      Instrucciones:
      - Extrae SOLO el nombre del área/barrio/distrito (ej: "Roma Norte", "Centro Histórico", "Polanco")
      - NO incluyas códigos postales, números, o la ciudad principal
      - Si no hay área específica, responde "Centro"
      - Responde en máximo 3 palabras
      
      Área:
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "extract_area_#{SecureRandom.hex(4)}",
        name: "Extract Area from Address",
        is_llm_task: true,
        input_data: { prompt: prompt }
      )
      
      workflow = Rdawn::Workflow.new(workflow_id: "area_extractor", name: "Area Extractor")
      workflow.add_task(task)
      
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
      result = agent.run
      
      area = result.tasks.values.first.output_data[:llm_response].strip
      
      # Limpiar la respuesta
      area = area.gsub(/['""]/, '').strip
      area = area.split(',').first&.strip || "Centro"
      
      puts "--- LLM extracted area: '#{area}' from address: #{address}"
      area
      
    rescue => e
      puts "--- Error extracting area with LLM: #{e.message}"
      "Centro"
    end
  end

  def calculate_vibe_match_with_google(qloo_entity, google_data, parsed_vibe)
    # Calcular match basado en datos disponibles
    base_score = qloo_entity ? calculate_vibe_match(qloo_entity, parsed_vibe) : 75
    
    # Bonus por tener datos de Google Places
    google_bonus = google_data ? 10 : 0
    
    # Bonus por rating alto
    rating_bonus = if google_data&.dig('rating')
      rating = google_data['rating'].to_f
      case rating
      when 4.5..5.0 then 15
      when 4.0..4.4 then 10
      when 3.5..3.9 then 5
      else 0
      end
    else
      0
    end
    
    # Bonus por relevancia de tipos
    type_bonus = if google_data&.dig('types')
      types = google_data['types']
      relevant_types = ['restaurant', 'food', 'bar', 'cafe', 'museum', 'tourist_attraction']
      (types & relevant_types).any? ? 5 : 0
    else
      0
    end
    
    final_score = [base_score + google_bonus + rating_bonus + type_bonus, 100].min
    puts "--- Calculated vibe match: #{final_score}% (base: #{base_score}, google: #{google_bonus}, rating: #{rating_bonus}, type: #{type_bonus})"
    
    final_score
  end

  # Eliminar las funciones de hardcoding
  def get_city_variations(city)
    # Ya no necesitamos hardcodear variaciones
    [city]
  end

  def similar_names?(name1, name2)
    return false unless name1 && name2
    
    # Usar LLM para comparación más inteligente si es necesario
    # Por ahora, comparación simple
    name1.downcase.include?(name2.downcase) || name2.downcase.include?(name1.downcase)
  end

  def extract_area_from_google_data(google_data, city)
    # Extraer área/distrito de la dirección de Google Places
    if google_data && google_data['formatted_address']
      address_parts = google_data['formatted_address'].split(',').map(&:strip)
      
      # Buscar el área que no sea la ciudad principal
      area_candidates = address_parts.reject do |part|
        part.downcase.include?(city.downcase) ||
        part.match?(/^\d/) || # No códigos postales
        part.length < 3 ||    # No partes muy cortas
        part.downcase.include?('mexico') ||
        part.downcase.include?('yuc') ||
        part.downcase.include?('n.l.')
      end
      
      # Devolver la primera parte válida o un default
      area_candidates.first || "Centro"
    else
      # Fallback basado en la ciudad
      case city
      when "Mérida"
        "Centro Histórico"
      when "Monterrey"
        "Centro"
      when "Mexico City"
        "Roma Norte"
      else
        "Distrito 1"
      end
    end
  end

  def calculate_vibe_match_with_google(qloo_entity, google_data, parsed_vibe)
    # Calcular match basado en datos de Qloo y Google
    base_score = qloo_entity ? calculate_vibe_match(qloo_entity, parsed_vibe) : 85
    
    # Bonus por tener datos de Google Places
    google_bonus = google_data ? 10 : 0
    
    # Bonus por rating alto
    rating_bonus = if google_data&.dig('rating')
      rating = google_data['rating'].to_f
      rating >= 4.5 ? 5 : rating >= 4.0 ? 3 : 0
    else
      0
    end
    
    [base_score + google_bonus + rating_bonus, 100].min
  end

  # *** FUNCIÓN ACTUALIZADA: Curate con ubicaciones de Google ***
def curate_experiences_with_explanations(parsed_vibe, qloo_data)
  puts "=== Curando experiencias con explicaciones culturales ==="
  
  city = parsed_vibe[:city]
  qloo_entities = qloo_data&.dig('results', 'entities') || []
  
  puts "=== QLOO ENTITIES FOUND: #{qloo_entities.size} ==="
  qloo_entities.each_with_index do |entity, i|
    puts "Entity #{i+1}: #{entity['name']} - #{entity['entity_id']}"
  end
  
  if qloo_entities.empty?
    puts "=== No hay datos de Qloo, usando experiencias de fallback ==="
    return create_fallback_experiences_with_explanations(parsed_vibe)
  end

  experiences = qloo_entities.first(3).map.with_index do |qloo_entity, index|
    puts "--- Procesando experiencia #{index + 1}: #{qloo_entity['name']} ---"
    
    # Extraer TODOS los datos de Qloo de forma más completa
    entity_properties = qloo_entity['properties'] || {}
    entity_location = qloo_entity['location'] || {}
    entity_tags = qloo_entity['tags'] || []
    
    # Coordenadas de Qloo (prioritarias)
    latitude = entity_location['lat']&.to_f
    longitude = entity_location['lon']&.to_f
    
    # Extraer keywords de Qloo de forma más robusta
    qloo_keywords = []
    if entity_properties['keywords'].is_a?(Array)
      qloo_keywords = entity_properties['keywords'].map { |k| k.is_a?(Hash) ? k['name'] : k.to_s }.compact
    elsif entity_properties['keywords'].is_a?(String)
      qloo_keywords = entity_properties['keywords'].split(',').map(&:strip)
    end
    
    # Si no hay keywords en properties, extraer de tags
    if qloo_keywords.empty? && entity_tags.any?
      qloo_keywords = entity_tags.map { |tag| tag['name'] }.compact.first(10)
    end
    
    puts "--- Keywords extraídas: #{qloo_keywords.inspect}"
    
    # Extraer información de contacto completa
    website = entity_properties['website']
    phone = entity_properties['phone']
    address = entity_properties['address']
    
    # Extraer información de horarios
    hours = entity_properties['hours']
    
    # Extraer información de precios
    price_level = entity_properties['price_level']&.to_i
    
    # Extraer rating
    rating = entity_properties['business_rating']&.to_f || 
             entity_properties['rating']&.to_f || 
             rand(4.0..5.0).round(1)
    
    # Extraer descripción más completa
    description = entity_properties['description'] || 
                  entity_properties['summary'] || 
                  entity_properties['editorial_summary'] ||
                  "Una experiencia cultural única curada especialmente para tu vibe."
    
    # Extraer imágenes
    images = entity_properties['images'] || []
    main_image = if images.any?
      images.first.is_a?(Hash) ? images.first['url'] : images.first
    else
      get_experience_image(index)
    end
    
    # Generar explicación cultural usando LLM
    cultural_explanation = generate_cultural_explanation(
      qloo_entity, 
      parsed_vibe, 
      qloo_keywords, 
      index
    )
    
    # Extraer área de forma más inteligente
    area = extract_area_from_qloo_entity(qloo_entity, city)
    
    # Calcular vibe match más sofisticado
    vibe_match = calculate_enhanced_vibe_match(qloo_entity, parsed_vibe, qloo_keywords)
    
    # Crear experiencia con TODOS los datos
    experience = {
      time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
      title: generate_experience_title(qloo_entity, index),
      location: qloo_entity['name'],
      description: description,
      cultural_explanation: cultural_explanation,
      duration: ["2 hours", "2.5 hours", "3 hours"][index],
      area: area,
      vibe_match: vibe_match,
      rating: rating,
      image: main_image,
      
      # *** DATOS COMPLETOS DE QLOO ***
      qloo_keywords: qloo_keywords,
      qloo_entity_id: qloo_entity['entity_id'],
      qloo_popularity: qloo_entity['popularity'],
      
      # *** INFORMACIÓN DE CONTACTO ***
      website: website,
      phone: phone,
      address: address,
      
      # *** COORDENADAS Y MAPAS ***
      latitude: latitude,
      longitude: longitude,
      google_maps_url: generate_google_maps_url(latitude, longitude, qloo_entity['name']),
      directions_url: generate_directions_url(latitude, longitude),
      
      # *** INFORMACIÓN OPERATIVA ***
      hours: hours,
      price_level: price_level,
      price_range: generate_price_range(price_level),
      
      # *** TAGS Y CATEGORÍAS ***
      tags: entity_tags,
      categories: extract_categories_from_tags(entity_tags),
      amenities: extract_amenities_from_tags(entity_tags),
      
      # *** INFORMACIÓN ADICIONAL ***
      why_chosen: generate_enhanced_why_chosen(qloo_entity, parsed_vibe, qloo_keywords),
      booking_info: extract_booking_info(entity_properties),
      accessibility: extract_accessibility_info(entity_tags),
      family_friendly: extract_family_friendly_info(entity_tags),
      
      # *** DATOS RAW PARA DEBUG ***
      qloo_raw_data: qloo_entity
    }
    
    puts "--- ✅ Experiencia #{index + 1} creada con #{qloo_keywords.size} keywords y coordenadas: #{latitude}, #{longitude}"
    puts "--- Website: #{website || 'N/A'}, Phone: #{phone || 'N/A'}"
    puts "--- Google Maps URL: #{experience[:google_maps_url]}"
    
    experience
  end
  
  puts "✅ Curadas #{experiences.size} experiencias con datos completos de Qloo"
  experiences
end

  def generate_cultural_explanation(entity, parsed_vibe, qloo_keywords, index)
    prompt = <<-PROMPT.strip
      Eres un curador cultural experto. Basándote en estos datos:

      Usuario busca: #{parsed_vibe[:interests].join(', ')} en #{parsed_vibe[:city]}
      Lugar: #{entity['name']}
      Descripción: #{entity.dig('properties', 'description') || entity.dig('properties', 'summary')}
      Keywords culturales: #{qloo_keywords.join(', ')}
      
      Explica en un párrafo evocador (máximo 100 palabras) por qué este lugar es perfecto para #{index == 0 ? 'comenzar' : index == 1 ? 'continuar' : 'culminar'} su aventura cultural. 
      
      Conecta los keywords de Qloo con la experiencia personal del usuario.
      Usa un tono cálido y poético.
      
      Responde solo con el párrafo explicativo.
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "explain_#{entity['entity_id'] || entity['id'] || SecureRandom.hex(4)}",
        name: "Generate Cultural Explanation",
        is_llm_task: true,
        input_data: { prompt: prompt }
      )
      
      workflow = Rdawn::Workflow.new(workflow_id: "explanation", name: "Cultural Explanation")
      workflow.add_task(task)
      
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
      result = agent.run
      
      explanation = result.tasks.values.first.output_data[:llm_response]
      explanation.strip.gsub(/^["']|["']$/, '') # Limpiar comillas
      
    rescue => e
      puts "❌ Error generando explicación cultural: #{e.message}"
      "Este lugar conecta perfectamente con tu búsqueda de #{parsed_vibe[:interests].join(' y ')} en #{parsed_vibe[:city]}."
    end
  end

  def generate_experience_title(entity, index)
    time_prefixes = ["Mañana:", "Tarde:", "Noche:"]
    descriptors = ["Descubrimiento Cultural", "Inmersión Auténtica", "Culminación Perfecta"]
    
    "#{time_prefixes[index]} #{descriptors[index]}"
  end

  def generate_why_chosen(entity, parsed_vibe, qloo_keywords)
    # Razón breve de por qué se eligió este lugar
    matching_keywords = (parsed_vibe[:interests] & qloo_keywords).any? ? 
      "Coincidencia directa con tus intereses" : 
      "Complementa perfectamente tu búsqueda cultural"
    
    "#{matching_keywords}. #{qloo_keywords.first(3).join(', ')}"
  end

  def create_fallback_experiences_with_explanations(parsed_vibe)
    city = parsed_vibe[:city] || 'tu destino'
    interests = parsed_vibe[:interests].join(', ')
    
    [
      {
        time: "10:00 AM",
        title: "Mañana: Descubrimiento Local",
        location: "Centro Cultural de #{city}",
        description: "Comienza explorando el corazón cultural de #{city}.",
        cultural_explanation: "Este lugar representa la esencia cultural de #{city}, perfectamente alineado con tu búsqueda de #{interests}.",
        duration: "2 hours",
        area: "Centro",
        vibe_match: 85,
        rating: 4.2,
        image: get_experience_image(0),
        qloo_keywords: [],
        why_chosen: "Seleccionado por su relevancia cultural en #{city}"
      },
      {
        time: "02:00 PM",
        title: "Tarde: Experiencia Auténtica",
        location: "Restaurante Tradicional",
        description: "Una pausa gastronómica que conecta con la tradición local.",
        cultural_explanation: "La gastronomía local es una ventana al alma de #{city}, y este lugar encarna esa esencia.",
        duration: "2.5 hours",
        area: "Distrito Histórico",
        vibe_match: 88,
        rating: 4.4,
        image: get_experience_image(1),
        qloo_keywords: [],
        why_chosen: "Elegido por su autenticidad gastronómica"
      },
      {
        time: "07:30 PM",
        title: "Noche: Culminación Cultural",
        location: "Espacio Cultural Nocturno",
        description: "Cierra tu día en un ambiente que captura la esencia nocturna de #{city}.",
        cultural_explanation: "La noche revela otra faceta de #{city}, y este lugar es el epítome de esa transformación cultural.",
        duration: "3 hours",
        area: "Zona de Entretenimiento",
        vibe_match: 82,
        rating: 4.1,
        image: get_experience_image(2),
        qloo_keywords: [],
        why_chosen: "Perfecto para culminar tu jornada cultural"
      }
    ]
  end

  def build_intelligent_narrative(parsed_vibe, user_vibe, experiences)
    city = parsed_vibe[:city]
    interests = parsed_vibe[:interests].join(', ')
    
    <<~HTML
      <div class="narrative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-8 rounded-2xl">
        <h2 class="text-3xl font-bold mb-6 gradient-text">🌟 Tu Aventura Cultural en #{city}</h2>
        
        <div class="glass-card p-6 mb-6">
          <p class="text-lg text-slate-300 mb-4">
            <strong class="text-white">Tu vibe original:</strong> 
            <em>"#{user_vibe}"</em>
          </p>
        </div>
        
        <div class="grid md:grid-cols-2 gap-6 mb-6">
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
              📍 <span style="color: var(--accent-terracotta);">Destino Identificado</span>
            </h3>
            <p class="text-slate-300">#{city}</p>
          </div>
          
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
              🎯 <span style="color: var(--accent-sage);">Intereses Detectados</span>
            </h3>
            <p class="text-slate-300">#{interests}</p>
          </div>
        </div>
        
        <div class="glass-card p-6">
          <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
            ✨ <span style="color: var(--accent-gold);">Curación Inteligente</span>
          </h3>
          <p class="text-slate-300">
            Usando datos culturales de Qloo API y análisis de IA, hemos diseñado #{experiences.size} experiencias 
            que capturan la esencia de #{city} y resuenan con tu búsqueda personal.
          </p>
        </div>
      </div>
    HTML
  end

# Replace the save_intelligent_itinerary method in ProcessVibeJobIntelligent

def save_intelligent_itinerary(user_vibe, parsed_vibe, narrative, experiences)
  city = parsed_vibe[:city] || 'Unknown City'
  preferences = parsed_vibe[:preferences]&.join(', ') || 'various preferences'
  
  itinerary = Itinerary.create!(
    user_id: 1,
    description: user_vibe,
    city: city,
    location: city,
    name: "Aventura Cultural en #{city}",
    narrative_html: narrative,
    themes: preferences
  )
  
  experiences.each_with_index do |exp, index|
    begin
      # Base attributes that should always exist
      attributes = {
        name: exp[:location],
        description: exp[:description],
        address: exp[:address] || "#{exp[:area]}, #{city}"
      }
      
      # Get available columns to avoid errors
      column_names = ItineraryStop.column_names
      
      # Add position if column exists
      attributes[:position] = index + 1 if column_names.include?('position')
      
      # Add coordinates if columns exist
      if column_names.include?('latitude') && column_names.include?('longitude')
        attributes[:latitude] = exp[:latitude]&.to_f
        attributes[:longitude] = exp[:longitude]&.to_f
      end
      
      # Add enhanced fields if they exist in the schema
      if column_names.include?('cultural_explanation')
        attributes[:cultural_explanation] = exp[:cultural_explanation]
      end
      
      if column_names.include?('why_chosen')
        attributes[:why_chosen] = exp[:why_chosen]
      end
      
      if column_names.include?('qloo_keywords')
        attributes[:qloo_keywords] = exp[:qloo_keywords]&.join(', ')
      end
      
      if column_names.include?('website')
        attributes[:website] = exp[:website]
      end
      
      if column_names.include?('phone')
        attributes[:phone] = exp[:phone]
      end
      
      if column_names.include?('rating')
        attributes[:rating] = exp[:rating]&.to_f
      end
      
      if column_names.include?('price_level')
        attributes[:price_level] = exp[:price_level]&.to_i
      end
      
      if column_names.include?('vibe_match')
        attributes[:vibe_match] = exp[:vibe_match]&.to_i
      end
      
      if column_names.include?('opening_hours')
        attributes[:opening_hours] = exp[:hours]&.to_json
      end
      
      if column_names.include?('image_url')
        attributes[:image_url] = exp[:image]
      end
      
      # Store all enhanced data as JSON if there's a flexible field
      if column_names.include?('qloo_data')
        enhanced_data = {
          # Core Qloo data
          qloo_entity_id: exp[:qloo_entity_id],
          qloo_popularity: exp[:qloo_popularity],
          qloo_keywords: exp[:qloo_keywords],
          
          # Enhanced contact and location
          google_maps_url: exp[:google_maps_url],
          directions_url: exp[:directions_url],
          website: exp[:website],
          phone: exp[:phone],
          
          # Operational info
          hours: exp[:hours],
          price_level: exp[:price_level],
          price_range: exp[:price_range],
          
          # Categories and features
          categories: exp[:categories],
          amenities: exp[:amenities],
          accessibility: exp[:accessibility],
          family_friendly: exp[:family_friendly],
          
          # Additional info
          booking_info: exp[:booking_info],
          cultural_explanation: exp[:cultural_explanation],
          why_chosen: exp[:why_chosen],
          vibe_match: exp[:vibe_match],
          
          # Raw data for debugging
          tags: exp[:tags]
        }.compact
        
        attributes[:qloo_data] = enhanced_data.to_json
      end
      
      # Create the stop with all available data
      stop = itinerary.itinerary_stops.create!(attributes)
      
      puts "✅ Enhanced stop creado: #{exp[:location]} (ID: #{stop.id})"
      puts "   - Coords: #{exp[:latitude]}, #{exp[:longitude]}"
      puts "   - Website: #{exp[:website] || 'N/A'}"
      puts "   - Phone: #{exp[:phone] || 'N/A'}"
      puts "   - Keywords: #{exp[:qloo_keywords]&.size || 0}"
      
    rescue => e
      puts "❌ Error creando enhanced stop: #{e.message}"
      puts "=== Columnas disponibles: #{ItineraryStop.column_names.inspect}"
      
      # Fallback: try with minimal data
      begin
        minimal_attributes = {
          name: exp[:location],
          description: exp[:description],
          address: "#{exp[:area]}, #{city}"
        }
        
        minimal_attributes[:position] = index + 1 if column_names.include?('position')
        
        fallback_stop = itinerary.itinerary_stops.create!(minimal_attributes)
        puts "✅ Fallback stop creado: #{exp[:location]} (ID: #{fallback_stop.id})"
        
      rescue => fallback_error
        puts "❌ Error en fallback stop: #{fallback_error.message}"
      end
    end
  end
  
  puts "✅ Enhanced itinerary guardado con ID: #{itinerary.id}"
  puts "   - Experiencias: #{experiences.size}"
  puts "   - Keywords totales: #{experiences.sum { |e| e[:qloo_keywords]&.size || 0 }}"
  puts "   - Lugares con coordenadas: #{experiences.count { |e| e[:latitude] && e[:longitude] }}"
  puts "   - Lugares con website: #{experiences.count { |e| e[:website] }}"
  puts "   - Lugares con teléfono: #{experiences.count { |e| e[:phone] }}"
  
  itinerary
end

  def calculate_vibe_match(entity, parsed_vibe)
    # Calcular match basado en popularidad de Qloo y coincidencias de intereses
    base_score = (entity['popularity'].to_f * 100).round
    
    # Bonus por coincidencias de keywords
    entity_keywords = entity.dig('properties', 'keywords') || []
    matches = (parsed_vibe[:interests] & entity_keywords).size
    bonus = matches * 5
    
    [[base_score + bonus, 95].min, 75].max
  end

  def extract_area_from_entity(entity, city)
    # Intentar extraer área de los datos de Qloo
    area = entity.dig('properties', 'geocode', 'name') ||
           entity.dig('properties', 'address')&.split(',')&.first ||
           'Centro'
    
    area.strip if area
  end

  def calculate_enhanced_vibe_match(qloo_entity, parsed_vibe, qloo_keywords)
  # Base score from Qloo popularity
  base_score = ((qloo_entity['popularity'] || 0.8).to_f * 100).round
  
  # Keyword matching bonus
  user_interests = parsed_vibe[:interests] || []
  keyword_matches = (user_interests & qloo_keywords).size
  keyword_bonus = keyword_matches * 10
  
  # Category matching bonus
  entity_tags = qloo_entity['tags'] || []
  category_bonus = 0
  
  entity_tags.each do |tag|
    tag_name = tag['name'].downcase
    user_interests.each do |interest|
      if tag_name.include?(interest.downcase) || interest.downcase.include?(tag_name)
        category_bonus += 5
      end
    end
  end
  
  # Quality bonus based on rating
  rating = qloo_entity.dig('properties', 'business_rating')&.to_f || 4.0
  quality_bonus = case rating
  when 4.5..5.0 then 10
  when 4.0..4.4 then 5
  else 0
  end
  
  final_score = [base_score + keyword_bonus + category_bonus + quality_bonus, 100].min
  [final_score, 75].max # Minimum 75%
end

  def extract_area_from_qloo_entity(qloo_entity, city)
  # Intentar extraer área de múltiples fuentes en Qloo
  area_candidates = [
    qloo_entity.dig('properties', 'geocode', 'name'),
    qloo_entity.dig('properties', 'neighborhood'),
    qloo_entity.dig('properties', 'district'),
    qloo_entity.dig('properties', 'area'),
    qloo_entity.dig('location', 'neighborhood'),
    qloo_entity.dig('properties', 'address')&.split(',')&.first
  ].compact.map(&:strip)
  
  # Filtrar candidatos válidos
  valid_area = area_candidates.find do |candidate|
    candidate.length > 2 && 
    !candidate.downcase.include?(city.downcase) &&
    !candidate.match?(/^\d+/) # No códigos postales
  end
  
  valid_area || "Centro"
end

  def generate_google_maps_url(latitude, longitude, place_name)
  return nil unless latitude && longitude
  
  # URL para abrir en Google Maps
  encoded_name = CGI.escape(place_name || "")
  "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}&query_place_id=#{encoded_name}"
end

def generate_directions_url(latitude, longitude)
  return nil unless latitude && longitude
  
  # URL para obtener direcciones
  "https://www.google.com/maps/dir/?api=1&destination=#{latitude},#{longitude}"
end

def generate_price_range(price_level)
  return nil unless price_level
  
  case price_level
  when 1 then "$"
  when 2 then "$$"
  when 3 then "$$$"
  when 4 then "$$$$"
  else "$-$$"
  end
end

def extract_categories_from_tags(tags)
  categories = []
  
  tags.each do |tag|
    if tag['type']&.include?('category')
      categories << tag['name']
    end
  end
  
  categories.uniq
end

def extract_amenities_from_tags(tags)
  amenities = []
  
  tags.each do |tag|
    if tag['type']&.include?('amenity')
      amenities << tag['name']
    end
  end
  
  amenities.uniq
end

def generate_enhanced_why_chosen(qloo_entity, parsed_vibe, qloo_keywords)
  # Razón más detallada
  matching_keywords = (parsed_vibe[:interests] & qloo_keywords)
  popularity_score = ((qloo_entity['popularity'] || 0.8) * 100).round
  
  reasons = []
  
  if matching_keywords.any?
    reasons << "Coincidencia directa con tus intereses: #{matching_keywords.join(', ')}"
  end
  
  if popularity_score >= 80
    reasons << "Alta popularidad cultural (#{popularity_score}%)"
  end
  
  if qloo_keywords.any?
    top_keywords = qloo_keywords.first(3)
    reasons << "Elementos culturales clave: #{top_keywords.join(', ')}"
  end
  
  reasons.any? ? reasons.join('. ') : "Curado especialmente para tu experiencia cultural única"
end

def extract_booking_info(properties)
  booking_info = {}
  
  booking_info[:reservation_required] = properties['reservation_required'] if properties['reservation_required']
  booking_info[:booking_url] = properties['booking_url'] if properties['booking_url']
  booking_info[:advance_booking] = properties['advance_booking_recommended'] if properties['advance_booking_recommended']
  
  booking_info.any? ? booking_info : nil
end

def extract_accessibility_info(tags)
  accessibility = []
  
  tags.each do |tag|
    if tag['type']&.include?('accessibility') || tag['name']&.downcase&.include?('wheelchair')
      accessibility << tag['name']
    end
  end
  
  accessibility.any? ? accessibility : nil
end

def extract_family_friendly_info(tags)
  family_features = []
  
  tags.each do |tag|
    tag_name = tag['name'].downcase
    if tag_name.include?('kid') || tag_name.include?('family') || tag_name.include?('children')
      family_features << tag['name']
    end
  end
  
  family_features.any? ? family_features : nil
end

  def get_experience_image(index)
    images = [
      "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3", 
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
    ]
    images[index] || images.first
  end
end