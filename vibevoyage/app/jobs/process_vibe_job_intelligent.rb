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

  def curate_experiences_with_explanations(parsed_vibe, qloo_data)
    puts "=== Curando experiencias con explicaciones culturales ==="
    
    city = parsed_vibe[:city]
    qloo_entities = qloo_data&.dig('results', 'entities') || []
    
    if qloo_entities.empty?
      puts "=== No hay datos de Qloo, usando experiencias de fallback ==="
      return create_fallback_experiences_with_explanations(parsed_vibe)
    end

    # Seleccionar las mejores 3 entidades
    selected_entities = qloo_entities.first(3)
    
    experiences = selected_entities.map.with_index do |entity, index|
      # Extraer keywords de Qloo para contexto cultural
      qloo_keywords = entity.dig('properties', 'keywords') || []
      
      # Generar explicación cultural usando LLM
      cultural_explanation = generate_cultural_explanation(
        entity, 
        parsed_vibe, 
        qloo_keywords, 
        index
      )
      
      {
        time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
        title: generate_experience_title(entity, index),
        location: entity['name'] || "Lugar Especial",
        description: entity.dig('properties', 'summary') || "Una experiencia cultural única.",
        cultural_explanation: cultural_explanation,
        duration: ["2 hours", "2.5 hours", "3 hours"][index],
        area: extract_area_from_entity(entity, city),
        vibe_match: calculate_vibe_match(entity, parsed_vibe),
        rating: entity.dig('properties', 'business_rating') || rand(4.0..5.0).round(1),
        image: get_experience_image(index),
        qloo_keywords: qloo_keywords,
        why_chosen: generate_why_chosen(entity, parsed_vibe, qloo_keywords),
        qloo_entity: entity
      }
    end
    
    puts "✅ Curadas #{experiences.size} experiencias con explicaciones"
    experiences
  end

  def generate_cultural_explanation(entity, parsed_vibe, qloo_keywords, index)
    prompt = <<-PROMPT.strip
      Eres un curador cultural experto. Basándote en estos datos:

      Usuario busca: #{parsed_vibe[:interests].join(', ')} en #{parsed_vibe[:city]}
      Lugar: #{entity['name']}
      Descripción: #{entity.dig('properties', 'summary')}
      Keywords culturales: #{qloo_keywords.join(', ')}
      
      Explica en un párrafo evocador (máximo 100 palabras) por qué este lugar es perfecto para #{index == 0 ? 'comenzar' : index == 1 ? 'continuar' : 'culminar'} su aventura cultural. 
      
      Conecta los keywords de Qloo con la experiencia personal del usuario.
      Usa un tono cálido y poético.
      
      Responde solo con el párrafo explicativo.
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "explain_#{entity['id'] || SecureRandom.hex(4)}",
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
