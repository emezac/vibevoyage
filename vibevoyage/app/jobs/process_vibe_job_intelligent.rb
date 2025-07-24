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
      
      # Resultado final para la interfaz de una sola página
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
              qloo_keywords: exp[:qloo_keywords] || [],
              why_chosen: exp[:why_chosen]
            }
          end
        }
      }
      
      update_status(process_id, 'complete', '¡Tu aventura está lista!', 100, itinerary: final_result[:itinerary])
      
      Rails.logger.info "ProcessVibeJobIntelligent completado para process_id: #{process_id}"
      
    rescue => e
      puts "=== ERROR en ProcessVibeJobIntelligent: #{e.message} ==="
      Rails.logger.error "ProcessVibeJobIntelligent falló: #{e.message}\n#{e.backtrace.join("\n")}"
      
      update_status(process_id, 'failed', "Error procesando tu vibe: #{e.message}", 100)
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
    
    puts "=== EJECUTANDO BÚSQUEDA GOOGLE PLACES DESDE CURATE ==="
    
    # *** LLAMAR A GOOGLE PLACES AQUÍ ***
    google_places_results = fetch_google_places_data(parsed_vibe, qloo_data)
    
    if google_places_results.empty?
      puts "=== No hay datos de Google Places, usando experiencias de fallback ==="
      return create_fallback_experiences_with_explanations(parsed_vibe)
    end

    experiences = google_places_results.first(3).map.with_index do |place_result, index|
      qloo_entity = place_result[:qloo_entity]
      google_data = place_result[:google_data]
      
      # Extraer coordenadas de Google Places
      location = google_data&.dig('geometry', 'location') || {}
      latitude = location['lat']
      longitude = location['lng']
      
      puts "--- Procesando experiencia #{index + 1}: #{place_result[:name]} - Coords: #{latitude}, #{longitude}"
      
      # Extraer keywords de Qloo para contexto cultural
      qloo_keywords = qloo_entity&.dig('properties', 'keywords')&.map { |k| k['name'] } || []
      
      # Generar explicación cultural usando LLM
      cultural_explanation = generate_cultural_explanation(
        qloo_entity || { 'name' => place_result[:name] }, 
        parsed_vibe, 
        qloo_keywords, 
        index
      )
      
      {
        time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
        title: generate_experience_title(qloo_entity || { 'name' => place_result[:name] }, index),
        location: place_result[:name],
        description: qloo_entity&.dig('properties', 'description') || google_data&.dig('editorial_summary', 'overview') || "Una experiencia cultural única.",
        cultural_explanation: cultural_explanation,
        duration: ["2 hours", "2.5 hours", "3 hours"][index],
        area: extract_area_from_google_data(google_data, city),
        vibe_match: calculate_vibe_match_with_google(qloo_entity, google_data, parsed_vibe),
        rating: google_data&.dig('rating') || qloo_entity&.dig('properties', 'business_rating') || rand(4.0..5.0).round(1),
        image: get_experience_image(index),
        # *** CAMPOS DE GOOGLE PLACES CON DEBUG ***
        latitude: latitude&.to_f,
        longitude: longitude&.to_f,
        place_id: google_data&.dig('place_id'),
        formatted_address: google_data&.dig('formatted_address'),
        qloo_keywords: qloo_keywords,
        why_chosen: generate_why_chosen(qloo_entity || { 'name' => place_result[:name] }, parsed_vibe, qloo_keywords),
        qloo_entity: qloo_entity,
        google_data: google_data
      }
    end
    
    puts "✅ Curadas #{experiences.size} experiencias con ubicaciones de Google Maps"
    experiences.each_with_index do |exp, index|
      puts "   #{index + 1}. #{exp[:location]} - Coords: #{exp[:latitude]}, #{exp[:longitude]}"
    end
    
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
        attributes = {
          name: exp[:location],
          description: exp[:description],
          address: "#{exp[:area]}, #{city}",
          cultural_explanation: exp[:cultural_explanation],
          why_chosen: exp[:why_chosen],
          qloo_keywords: exp[:qloo_keywords]&.join(', ')
        }
        
        column_names = ItineraryStop.column_names
        attributes[:position] = index + 1 if column_names.include?('position')
        attributes[:latitude] = nil if column_names.include?('latitude')
        attributes[:longitude] = nil if column_names.include?('longitude')
        
        # Solo agregar campos que existen en la tabla
        if column_names.include?('cultural_explanation')
          # El campo ya está en attributes
        else
          # Guardar en qloo_data como JSON si no hay campo específico
          if column_names.include?('qloo_data')
            attributes[:qloo_data] = {
              cultural_explanation: exp[:cultural_explanation],
              why_chosen: exp[:why_chosen],
              qloo_keywords: exp[:qloo_keywords]
            }.to_json
          end
        end
        
        stop = itinerary.itinerary_stops.create!(attributes)
        puts "✅ Stop creado: #{exp[:location]} (ID: #{stop.id})"
        
      rescue => e
        puts "❌ Error creando stop: #{e.message}"
        puts "=== Columnas disponibles: #{ItineraryStop.column_names.inspect}"
      end
    end
    
    puts "✅ Itinerario inteligente guardado con ID: #{itinerary.id}"
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

  def get_experience_image(index)
    images = [
      "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3", 
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
    ]
    images[index] || images.first
  end
end