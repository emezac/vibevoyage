# app/jobs/process_vibe_job_intelligent.rb
class ProcessVibeJobIntelligent < ApplicationJob
  queue_as :default

  def perform(process_id, user_vibe)
    start_time = Time.current
    
    puts "=== STARTING ProcessVibeJobIntelligent (Corrected Flow) ==="
    puts "Process ID: #{process_id}"
    puts "User vibe: #{user_vibe}"
    
    begin
      # PASO 1: ANALIZAR VIBE DEL USUARIO (15%)
      # Se determina el idioma, la ciudad y los intereses.
      update_qloo_status(process_id, 'analyzing', 'analyzing_vibe', 15)
      parsed_vibe = parse_user_vibe(user_vibe, process_id)
      language = parsed_vibe[:detected_language]
      
      # PASO 2: OBTENER DATOS BRUTOS DE QLOO (35%)
      # Se consultan las recomendaciones iniciales de Qloo.
      update_qloo_status(process_id, 'querying_qloo', 'querying_qloo', 35, { language: language })
      recommendations_result = fetch_qloo_recommendations(parsed_vibe)
      
      unless recommendations_result[:success]
        handle_qloo_error(process_id, recommendations_result[:error])
        return
      end
      
      qloo_data = recommendations_result[:data]
      show_qloo_discoveries(process_id, qloo_data.dig('results', 'entities') || [], parsed_vibe, 50)

      # PASO 3: GENERAR PERFIL DE ADN CULTURAL (60%)
      # Usando los intereses y los datos de Qloo, el LLM crea el perfil de ADN.
      service = LlmService.new
      #cultural_dna_data = service.generate_cultural_dna_profile(parsed_vibe, qloo_data)
      update_qloo_status(process_id, 'analyzing', 'dna_analysis', 60, { message: "Decoding cultural genome..." })
      cultural_dna_data = LlmService.generate_cultural_dna_profile(parsed_vibe, qloo_data)

      # PASO 4: ENRIQUECER LUGARES CON GOOGLE PLACES (65%)
      # Se toman las entidades de Qloo y se enriquecen con datos verificados (dirección, sitio web, etc.).
      update_qloo_status(process_id, 'enriching', 'enriching_places', 65, { language: language })
      enriched_places = PlacesEnrichmentService.process_places_data(parsed_vibe, qloo_data)
      
      # PASO 5: CURAR EXPERIENCIAS (80%)
      # Se toma la lista de lugares YA ENRIQUECIDOS y se les añade la capa narrativa y cultural.
      update_qloo_status(process_id, 'curating', 'building_narrative', 80, { language: language })
      final_experiences = CulturalCurationService.curate_experiences_from_enriched_places(
        enriched_places, 
        parsed_vibe
      )
      
      AnalyticsService.track_curation_effectiveness(final_experiences)

      # PASO 6: CONSTRUIR NARRATIVA Y GUARDAR EN BASE DE DATOS (95%)
      # Se crea el HTML narrativo y se guarda el itinerario completo.
      update_qloo_status(process_id, 'finalizing', 'cultural_synthesis', 95, { language: language })
      narrative = build_localized_narrative(parsed_vibe, user_vibe, final_experiences)
      itinerary = save_enhanced_itinerary(user_vibe, parsed_vibe, narrative, final_experiences)
      
      # PASO 7: TRACKING DE ANALYTICS
      # Se registran las métricas del proceso completo.
      total_duration = Time.current - start_time
      AnalyticsService.track_journey_processing(process_id, user_vibe, parsed_vibe, final_experiences, total_duration)
      
      # PASO 8: CONSTRUIR Y ENVIAR RESULTADO FINAL AL FRONTEND (100%)
      # Se ensambla el objeto JSON final que el frontend espera.

      final_result = build_final_result(itinerary, parsed_vibe, final_experiences, cultural_dna_data)
      update_qloo_status(process_id, 'complete', 'ready', 100, { 
        itinerary: final_result[:itinerary],
        itinerary_id: itinerary.id  # ✅ Agregar esta línea
      })

      log_completion_stats(process_id, final_result, total_duration)

    rescue => e
      # Manejo de errores para todo el proceso.
      AnalyticsService.track_error('process_vibe_job', 'full_processing', e, { process_id: process_id, user_vibe_length: user_vibe.length, processing_stage: determine_processing_stage(e) })
      handle_processing_error(e, process_id, user_vibe)
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

  def parse_user_vibe(user_vibe, process_id)
    # Try workflow parsing first, fall back to direct LLM
    begin
      if defined?(::Workflows::VibeVoyageWorkflow)
        parse_vibe_with_workflow(user_vibe, process_id)
      else
        LLMService.parse_vibe(user_vibe)
      end
    rescue => e
      Rails.logger.error "Workflow parsing failed: #{e.message}"
      # Track LLM parsing error
      AnalyticsService.track_llm_performance('vibe_parsing', 0, false, nil, e)
      LLMService.parse_vibe(user_vibe)
    end
  end

  def parse_vibe_with_workflow(user_vibe, process_id)
    #vibe_parser_task_data = ::Workflows::VibeVoyageWorkflow.tasks.first
    tasks_array = ::Workflows::VibeVoyageWorkflow.tasks
    vibe_parser_task_data = tasks_array.find { |task| task[:id] == :parse_vibe }

    unless vibe_parser_task_data
      raise "La tarea :parse_vibe no fue encontrada en VibeVoyageWorkflow"
    end

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
    
    parsed_data = extract_json_from_llm_response(llm_response_json).deep_symbolize_keys
    # Add detected language
    parsed_data[:detected_language] = LocalizationService.detect_language(user_vibe)
    
    parsed_data
  end

  def fetch_qloo_recommendations(parsed_vibe)
    Rails.logger.info "--- Calling Qloo with: interests=#{parsed_vibe[:interests].inspect}, city=#{parsed_vibe[:city].inspect}"
    
    RdawnApiService.qloo_recommendations(
      interests: parsed_vibe[:interests],
      city: parsed_vibe[:city],
      preferences: parsed_vibe[:preferences]
    )
  end

  def enhance_experiences_with_places_data(experiences, places_results, parsed_vibe)
    language = parsed_vibe[:detected_language]
    
    experiences.map.with_index do |experience, index|
      # Find corresponding place result
      place_result = places_results[index] if places_results[index]
      
      if place_result
        # Extract enhanced data from places enrichment
        enhanced_data = extract_enhanced_place_data(place_result, parsed_vibe)
        
        # Merge with existing experience data
        experience.merge(enhanced_data)
      else
        # Use original experience with fallback coordinates if needed
        ensure_coordinates_fallback(experience, parsed_vibe)
      end
    end
  end

  def ensure_coordinates_fallback(experience, parsed_vibe)
    # If experience doesn't have coordinates, try to generate them
    unless experience[:latitude] && experience[:longitude]
      begin
        fallback_coords = LLMService.generate_fallback_coordinates(
          parsed_vibe[:city], 
          experience[:location]
        )
        
        experience[:latitude] = fallback_coords[:latitude]
        experience[:longitude] = fallback_coords[:longitude]
        experience[:coordinate_precision] = 'llm_generated'
        
        # Generate basic URLs with fallback coordinates
        if experience[:latitude] && experience[:longitude]
          urls = CulturalCurationService.generate_enhanced_urls(
            experience[:latitude],
            experience[:longitude],
            experience[:location]
          )
          experience.merge!(urls)
        end
        
      rescue => e
        Rails.logger.error "Failed to generate fallback coordinates: #{e.message}"
        AnalyticsService.track_error(
          'llm_service', 
          'fallback_coordinates', 
          e,
          { city: parsed_vibe[:city], location: experience[:location] }
        )
      end
    end
    
    experience
  end

  def extract_amenities_from_types(types)
    amenities = []
    
    types.each do |type|
      case type
      when 'wheelchair_accessible_entrance' then amenities << 'wheelchair_accessible'
      when 'accepts_credit_cards' then amenities << 'credit_cards'
      when 'outdoor_seating' then amenities << 'outdoor_seating'
      when 'wifi' then amenities << 'wifi'
      when 'parking' then amenities << 'parking'
      when 'reservations' then amenities << 'reservations'
      end
    end
    
    amenities
  end

  def build_localized_narrative(parsed_vibe, user_vibe, experiences)
    language = parsed_vibe[:detected_language]
    
    LocalizationService.build_narrative_html(
      user_vibe,
      parsed_vibe[:city],
      parsed_vibe[:interests],
      experiences.size,
      language
    )
  end

  def save_enhanced_itinerary(user_vibe, parsed_vibe, narrative, experiences)
    city = parsed_vibe[:city] || 'Unknown City'
    preferences = parsed_vibe[:preferences]&.join(', ') || 'various preferences'
    language = parsed_vibe[:detected_language]
    
    # Generate localized itinerary name
    itinerary_name = LocalizationService.adventure_title(city, language)
    
    itinerary = Itinerary.create!(
      user_id: 1,
      description: user_vibe,
      city: city,
      location: city,
      name: itinerary_name,
      narrative_html: narrative,
      themes: preferences
    )
    
    save_enhanced_itinerary_stops(itinerary, experiences)
    
    log_itinerary_creation(itinerary, experiences, language)
    
    itinerary
  end

  def save_enhanced_itinerary_stops(itinerary, experiences)
    column_names = ItineraryStop.column_names
    
    experiences.each_with_index do |exp, index|
      begin
        attributes = build_enhanced_stop_attributes(exp, index, column_names)
        stop = itinerary.itinerary_stops.create!(attributes)
        
        Rails.logger.info "✅ Enhanced stop created: #{exp[:location]} (ID: #{stop.id}) - Quality: #{exp[:data_quality]} - Sources: #{exp[:data_sources]&.join(', ')}"
        
      rescue => e
        Rails.logger.error "❌ Error creating stop: #{e.message}"
        AnalyticsService.track_error(
          'itinerary_creation', 
          'stop_creation', 
          e,
          { experience_name: exp[:location], experience_index: index }
        )
        create_fallback_stop(itinerary, exp, index, column_names)
      end
    end
  end

  def build_enhanced_stop_attributes(exp, index, column_names)
    # Base required attributes
    attributes = {
      name: exp[:location],
      description: exp[:description],
      address: exp[:address] || "#{exp[:area]}, #{exp[:city] || 'Unknown'}"
    }
    
    # Add optional attributes if columns exist
    optional_attributes = {
      position: index + 1,
      latitude: exp[:latitude]&.to_f,
      longitude: exp[:longitude]&.to_f,
      cultural_explanation: exp[:cultural_explanation],
      why_chosen: exp[:why_chosen],
      qloo_keywords: exp[:qloo_keywords]&.join(', '),
      website: exp[:website],
      phone: exp[:phone],
      rating: exp[:rating]&.to_f,
      price_level: exp[:price_level]&.to_i,
      vibe_match: exp[:vibe_match]&.to_i,
      opening_hours: exp[:hours]&.to_json,
      image_url: exp[:image],
      area: exp[:area]
    }
    
    # Only add attributes for existing columns
    optional_attributes.each do |key, value|
      attributes[key] = value if column_names.include?(key.to_s) && value.present?
    end
    
    # Store enhanced data as JSON if qloo_data column exists
    if column_names.include?('qloo_data')
      attributes[:qloo_data] = build_comprehensive_data_json(exp).to_json
    end
    
    attributes
  end

  def build_comprehensive_data_json(exp)
    {
      # Core Qloo data
      qloo_entity_id: exp[:qloo_entity_id],
      qloo_popularity: exp[:qloo_popularity],
      qloo_keywords: exp[:qloo_keywords],
      
      # Enhanced contact and location
      google_maps_url: exp[:google_maps_url],
      directions_url: exp[:directions_url],
      share_url: exp[:share_url],
      
      # Operational info
      hours: exp[:hours],
      price_range: exp[:price_range],
      
      # Categories and features
      categories: exp[:categories],
      amenities: exp[:amenities],
      accessibility: exp[:accessibility],
      family_friendly: exp[:family_friendly],
      
      # Additional info
      booking_info: exp[:booking_info],
      why_chosen: exp[:why_chosen],
      vibe_match: exp[:vibe_match],
      tags: exp[:tags],
      
      # Data quality metadata
      data_quality: exp[:data_quality],
      data_sources: exp[:data_sources],
      coordinate_precision: exp[:coordinate_precision],
      last_enriched: Time.current.iso8601
    }.compact
  end

  def create_fallback_stop(itinerary, exp, index, column_names)
    minimal_attributes = {
      name: exp[:location],
      description: exp[:description],
      address: "#{exp[:area]}, Unknown City"
    }
    
    minimal_attributes[:position] = index + 1 if column_names.include?('position')
    
    fallback_stop = itinerary.itinerary_stops.create!(minimal_attributes)
    Rails.logger.info "✅ Fallback stop created: #{exp[:location]} (ID: #{fallback_stop.id})"
  end

  def build_final_result(itinerary, parsed_vibe, curated_experiences, cultural_dna_data) # <--- NUEVO PARÁMETRO
    language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
    ui_translations = LocalizationService.get_ui_translations(language)
    
    {
      status: 'complete',
      message: LocalizationService.success_message(language: language),
      progress: 100,
      itinerary: {
        id: itinerary.id,
        title: LocalizationService.adventure_title(parsed_vibe[:city], language),
        city: parsed_vibe[:city],
        language: language,
        ui_translations: ui_translations,
        
        # ¡AQUÍ ESTÁ LA MAGIA! AHORA USAMOS LOS DATOS DINÁMICOS
        cultural_dna: cultural_dna_data,
        
        experiences: curated_experiences.map.with_index do |exp, index|
          build_comprehensive_experience_response(exp, itinerary, index)
        end
      }
    }
  end

  def handle_qloo_error(process_id, error_message)
    error_msg = "Error fetching recommendations: #{error_message}"
    update_status(process_id, 'failed', error_msg, 100)
    Rails.logger.error error_msg
  end

  def handle_processing_error(error, process_id, user_vibe)
    Rails.logger.error "ProcessVibeJobIntelligent failed: #{error.message}\n#{error.backtrace.join("\n")}"
    
    begin
      puts "=== Attempting fallback response ==="
      update_status(process_id, 'processing', 'Creating fallback experience...', 75)
      
      # Create fallback with language detection
      fallback_result = create_comprehensive_fallback(user_vibe, process_id)
      
      success_message = LocalizationService.success_message(
        offline: true, 
        language: fallback_result[:language]
      )
      
      update_status(process_id, 'complete', success_message, 100, itinerary: fallback_result[:itinerary])
      puts "✅ Fallback response created successfully"
      
    rescue => fallback_error
      puts "=== FALLBACK ALSO FAILED: #{fallback_error.message} ==="
      AnalyticsService.track_error(
        'process_vibe_job', 
        'fallback_creation', 
        fallback_error,
        { process_id: process_id, original_error: error.message }
      )
      update_status(process_id, 'failed', "Error processing your vibe: #{error.message}", 100)
    end
  end

  def create_comprehensive_fallback(user_vibe, process_id)
    # Simple vibe parsing for fallback
    detected_language = LocalizationService.detect_language(user_vibe)
    
    parsed_vibe = {
      city: extract_city_from_text(user_vibe),
      interests: extract_interests_from_text(user_vibe),
      preferences: ['culture', 'authentic'],
      detected_language: detected_language
    }
    
    # Create fallback experiences using LocalizationService
    fallback_experiences = LocalizationService.generate_fallback_experiences(
      parsed_vibe[:city], 
      parsed_vibe[:interests], 
      detected_language
    )
    
    # Create fallback narrative
    fallback_narrative = LocalizationService.build_narrative_html(
      user_vibe,
      parsed_vibe[:city],
      parsed_vibe[:interests],
      fallback_experiences.size,
      detected_language
    )
    
    # Save fallback itinerary
    fallback_itinerary = save_enhanced_itinerary(user_vibe, parsed_vibe, fallback_narrative, fallback_experiences)
    
    # Track fallback usage
    AnalyticsService.track_journey_processing(
      process_id,
      user_vibe,
      parsed_vibe,
      fallback_experiences,
      0.5 # Minimal processing time for fallback
    )
    
    {
      language: detected_language,
      itinerary: {
        id: fallback_itinerary.id,
        title: LocalizationService.adventure_title(parsed_vibe[:city], detected_language),
        city: parsed_vibe[:city],
        narrative_html: fallback_narrative,
        experiences: fallback_experiences.map.with_index do |exp, index|
          build_fallback_experience_response(exp, fallback_itinerary, index)
        end
      }
    }
  end

  def build_fallback_experience_response(exp, itinerary, index)
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
      why_chosen: exp[:why_chosen],
      # Set metadata for fallback
      data_quality: 'fallback',
      data_sources: ['localization_service'],
      coordinate_precision: 'none',
      # Set other enhanced fields to nil for fallback
      qloo_entity_id: nil,
      qloo_popularity: nil,
      website: nil,
      phone: nil,
      address: nil,
      latitude: nil,
      longitude: nil,
      google_maps_url: nil,
      directions_url: nil,
      hours: nil,
      price_level: nil,
      price_range: nil,
      tags: [],
      categories: [],
      amenities: [],
      accessibility: nil,
      family_friendly: nil,
      booking_info: nil
    }.compact
  end

  # Helper methods for error tracking and processing stage determination
  def determine_processing_stage(error)
    case error.message
    when /parse|vibe|language/ then 'vibe_parsing'
    when /qloo|recommendation/ then 'qloo_api'
    when /places|enrichment/ then 'places_enrichment'
    when /curation|cultural/ then 'cultural_curation'
    when /narrative|localization/ then 'narrative_building'
    when /itinerary|save/ then 'database_saving'
    else 'unknown'
    end
  end

  # Helper methods for fallback parsing
  def extract_city_from_text(text)
    cities = ['Mexico City', 'Toronto', 'New York', 'London', 'Paris', 'Tokyo', 'Madrid', 'Barcelona', 'Rome', 'Berlin']
    cities.find { |city| text.downcase.include?(city.downcase) } || 'Mexico City'
  end

  def extract_interests_from_text(text)
    text_lower = text.downcase
    interests = []
    
    interests << 'restaurant' if text_lower.match?(/food|restaurant|eat|gastronom/)
    interests << 'bar' if text_lower.match?(/drink|bar|cocktail|wine|beer/)
    interests << 'museum' if text_lower.match?(/art|museum|gallery|cultura/)
    interests << 'music' if text_lower.match?(/music|concert|vinyl|sound/)
    interests << 'bookstore' if text_lower.match?(/book|read|library|edition/)
    interests << 'cinema' if text_lower.match?(/cinem|movie|film/)
    
    interests << 'culture' if interests.empty?
    interests
  end

  def extract_json_from_llm_response(response_text)
    cleaned_text = response_text.strip.gsub(/^```json\n?/, '').gsub(/\n?```$/, '')
    JSON.parse(cleaned_text)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse LLM response: #{cleaned_text}"
    raise e
  end

  def log_completion_stats(process_id, final_result, total_duration)
    experiences = final_result[:itinerary][:experiences]
    
    # Enhanced logging with data quality metrics
    high_quality_count = experiences.count { |e| e[:data_quality] == 'high' }
    coords_count = experiences.count { |e| e[:latitude] && e[:longitude] }
    website_count = experiences.count { |e| e[:website] }
    phone_count = experiences.count { |e| e[:phone] }
    total_keywords = experiences.sum { |e| e[:qloo_keywords]&.size || 0 }
    
    Rails.logger.info "ProcessVibeJobIntelligent completed for process_id: #{process_id}"
    Rails.logger.info "--- Total processing time: #{total_duration.round(2)} seconds"
    Rails.logger.info "--- Total experiences: #{experiences.size}"
    Rails.logger.info "--- High quality experiences: #{high_quality_count}/#{experiences.size}"
    Rails.logger.info "--- Experiences with coordinates: #{coords_count}/#{experiences.size}"
    Rails.logger.info "--- Experiences with website: #{website_count}/#{experiences.size}"
    Rails.logger.info "--- Experiences with phone: #{phone_count}/#{experiences.size}"
    Rails.logger.info "--- Total keywords: #{total_keywords}"
    
    # Data source breakdown
    data_sources = experiences.flat_map { |e| e[:data_sources] || [] }.tally
    Rails.logger.info "--- Data sources: #{data_sources.inspect}"
  end

  def log_itinerary_creation(itinerary, experiences, language)
    puts "✅ Enhanced itinerary saved with ID: #{itinerary.id}"
    puts "   - Language: #{language}"
    puts "   - Experiences: #{experiences.size}"
    puts "   - Total keywords: #{experiences.sum { |e| e[:qloo_keywords]&.size || 0 }}"
    puts "   - Places with coordinates: #{experiences.count { |e| e[:latitude] && e[:longitude] }}"
    puts "   - Places with website: #{experiences.count { |e| e[:website] }}"
    puts "   - Places with phone: #{experiences.count { |e| e[:phone] }}"
    puts "   - Data quality breakdown:"
    
    quality_breakdown = experiences.group_by { |e| e[:data_quality] }.transform_values(&:count)
    quality_breakdown.each { |quality, count| puts "     #{quality}: #{count}" }
  end

  private

  def extract_enhanced_place_data(place_result, parsed_vibe)
    google_data = place_result[:google_data]
    qloo_entity = place_result[:qloo_entity]
    metadata = place_result[:metadata] || {}
    language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
    
    Rails.logger.info "--- Extracting enhanced data for language: #{language}"
    
    enhanced_data = {}
    
    # Extract coordinates
    if google_data&.dig('geometry', 'location')
      coords = google_data['geometry']['location']
      enhanced_data[:latitude] = coords['lat']
      enhanced_data[:longitude] = coords['lng']
      
      # Generate enhanced URLs
      urls = CulturalCurationService.generate_enhanced_urls(
        coords['lat'], 
        coords['lng'], 
        google_data['name']
      )
      enhanced_data.merge!(urls)
    end
    
    # Extract contact information
    enhanced_data[:website] = google_data&.dig('website')
    enhanced_data[:phone] = google_data&.dig('formatted_phone_number')
    enhanced_data[:address] = google_data&.dig('formatted_address')
    
    # Extract operational information
    enhanced_data[:rating] = google_data&.dig('rating')&.to_f
    enhanced_data[:price_level] = google_data&.dig('price_level')&.to_i
    enhanced_data[:hours] = google_data&.dig('opening_hours')
    enhanced_data[:opening_hours] = enhanced_data[:hours] # Alias

    unless enhanced_data[:hours]
      qloo_hours = extract_hours_from_qloo(qloo_entity) if qloo_entity
      enhanced_data[:hours] = qloo_hours if qloo_hours
      enhanced_data[:opening_hours] = qloo_hours if qloo_hours
    end
    
    # Extract area with multiple fallback strategies
    if defined?(PlacesEnrichmentService)
      enhanced_data[:area] = PlacesEnrichmentService.extract_area_with_fallback(
        google_data, 
        qloo_entity, 
        parsed_vibe[:city], 
        language
      )
    else
      enhanced_data[:area] = LocalizationService.localize('areas.center', language)
    end
    
    # Add metadata information
    enhanced_data[:data_quality] = metadata[:data_quality]
    enhanced_data[:data_sources] = metadata[:data_sources]
    enhanced_data[:coordinate_precision] = metadata[:coordinate_precision]
    
    # *** ENHANCED CATEGORY PROCESSING WITH TRANSLATIONS ***
    if google_data&.dig('types')
      raw_categories = google_data['types']
      enhanced_data[:categories] = raw_categories
      enhanced_data[:raw_categories] = raw_categories # Keep original for debugging
      
      Rails.logger.info "--- Raw categories: #{raw_categories.inspect}"
      
      # *** TRANSLATE CATEGORIES USING CategoryTranslationHelper ***
      if defined?(CategoryTranslationHelper)
        enhanced_data[:translated_categories] = CategoryTranslationHelper.translate_categories(
          raw_categories, 
          language
        )
        
        # Get primary category with icon
        primary_category = raw_categories.first
        enhanced_data[:category_icon] = CategoryTranslationHelper.get_category_icon(primary_category)
        enhanced_data[:primary_category] = CategoryTranslationHelper.translate_google_place_type(
          primary_category, 
          language
        )
        
        Rails.logger.info "--- Translated categories: #{enhanced_data[:translated_categories].inspect}"
        Rails.logger.info "--- Primary category: #{enhanced_data[:primary_category]}"
        Rails.logger.info "--- Category icon: #{enhanced_data[:category_icon]}"
      else
        Rails.logger.warn "CategoryTranslationHelper not available"
        enhanced_data[:translated_categories] = raw_categories&.map(&:humanize) || []
        enhanced_data[:primary_category] = raw_categories&.first&.humanize || 'Experience'
        enhanced_data[:category_icon] = '📍'
      end
      
      enhanced_data[:amenities] = extract_amenities_from_types(raw_categories)
    else
      Rails.logger.warn "No types found in Google data"
      enhanced_data[:translated_categories] = []
      enhanced_data[:primary_category] = 'Experience'
      enhanced_data[:category_icon] = '📍'
    end
    
    Rails.logger.info "--- Enhanced data keys: #{enhanced_data.keys}"
    enhanced_data.compact
  end

  def build_comprehensive_experience_response(exp, itinerary, index)
    {
      # *** BASIC FIELDS ***
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
      
      # *** QLOO DATA ***
      qloo_keywords: exp[:qloo_keywords] || [],
      qloo_entity_id: exp[:qloo_entity_id],
      qloo_popularity: exp[:qloo_popularity],
      why_chosen: exp[:why_chosen],
      
      # *** CONTACT AND LOCATION ***
      website: exp[:website],
      phone: exp[:phone],
      address: exp[:address],
      latitude: exp[:latitude],
      longitude: exp[:longitude],
      google_maps_url: exp[:google_maps_url],
      directions_url: exp[:directions_url],
      share_url: exp[:share_url],
      
      # *** OPERATIONAL INFO ***
      hours: exp[:hours],
      price_level: exp[:price_level],
      price_range: exp[:price_range],
      
      # *** CATEGORIES AND FEATURES (ENHANCED) ***
      tags: exp[:tags] || [],
      categories: exp[:categories] || [], # Raw categories for backwards compatibility
      raw_categories: exp[:raw_categories] || [], # Original Google Places types
      translated_categories: exp[:translated_categories] || [], # *** NUEVO ***
      category_icon: exp[:category_icon], # *** NUEVO ***
      primary_category: exp[:primary_category], # *** NUEVO ***
      amenities: exp[:amenities] || [],
      accessibility: exp[:accessibility],
      family_friendly: exp[:family_friendly],
      
      # *** ADDITIONAL INFO ***
      booking_info: exp[:booking_info],
      
      # *** DATA QUALITY METADATA ***
      data_quality: exp[:data_quality],
      data_sources: exp[:data_sources],
      coordinate_precision: exp[:coordinate_precision]
    }.compact
  end

  # Enhanced status update method with Qloo context
  def update_qloo_status(process_id, status, message_key, progress, extra_data = {})
    language = extra_data[:language] || 'en'
    
    # Use the discovery message directly if provided
    if extra_data[:discovery]
      base_message = extra_data[:discovery]
    else
      # Get localized message
      messages = LocalizationService.get_progress_messages(language)
      base_message = messages[message_key.to_sym] || message_key.to_s.humanize
      
      # Apply interpolations if needed
      if extra_data[:interests_count]
        base_message = base_message % { interests_count: extra_data[:interests_count] }
      end
    end
    
    status_data = { 
      status: status, 
      message: base_message, 
      progress: progress,
      qloo_data: extra_data.except(:language, :interests_count, :discovery, :itinerary, :itinerary_id)
    }.compact
    
    # Add itinerary if complete
    if extra_data[:itinerary]
      status_data[:itinerary] = extra_data[:itinerary]
    end
    
    # ✅ AGREGAR: Include itinerary_id directly for sharing functionality
    if extra_data[:itinerary_id]
      status_data[:itinerary_id] = extra_data[:itinerary_id]
    end
    
    Rails.cache.write("journey_#{process_id}", status_data, expires_in: 15.minutes)
    puts "=== Enhanced Status Update: #{progress}% - #{base_message} ==="
  end
  
  # Show Qloo discoveries with dramatic effect
  def show_qloo_discoveries(process_id, qloo_entities, parsed_vibe, base_progress)
    language = parsed_vibe[:detected_language]
    user_interests = parsed_vibe[:interests] || []
    
    # Collect all keywords from Qloo entities
    all_keywords = []
    entity_discoveries = []
    
    qloo_entities.first(3).each do |entity|
      entity_name = entity['name']
      entity_keywords = extract_qloo_keywords_for_display(entity)
      
      if entity_keywords.any?
        all_keywords.concat(entity_keywords)
        entity_discoveries << {
          name: entity_name,
          keywords: entity_keywords.first(4) # Limit for display
        }
      end
    end
    
    # Show discoveries for each user interest
    user_interests.each_with_index do |interest, index|
      progress = base_progress + (index * 3) # Increment progress slightly
      
      # Find related keywords for this interest
      related_keywords = find_related_keywords(interest, all_keywords)
      
      if related_keywords.any?
        # Fixed interpolation - do it manually instead of using LocalizationService
        case language
        when 'fr'
          discovery_message = "✨ Découverte! Les fans de \"#{interest}\" aiment aussi: #{related_keywords.join(', ')}"
        when 'es'
          discovery_message = "✨ ¡Descubrimiento! A los fans de \"#{interest}\" también les gusta: #{related_keywords.join(', ')}"
        else
          discovery_message = "✨ Discovery! Fans of \"#{interest}\" also love: #{related_keywords.join(', ')}"
        end
        
        update_qloo_status(process_id, 'querying_qloo', 'qloo_discovery', progress, {
          language: language,
          discovery: discovery_message,
          interest: interest,
          related_keywords: related_keywords,
          entity_discoveries: entity_discoveries
        })
        
        # Small delay for dramatic effect
        sleep(0.6)
      end
    end
    
    # Final connections summary
    total_connections = all_keywords.uniq.size
    
    case language
    when 'fr'
      connections_message = "🧠 Qloo a trouvé #{total_connections} connexions culturelles"
    when 'es'
      connections_message = "🧠 Qloo encontró #{total_connections} conexiones culturales"
    else
      connections_message = "🧠 Qloo found #{total_connections} cultural connections"
    end
    
    update_qloo_status(process_id, 'querying_qloo', 'qloo_connections', base_progress + 8, {
      language: language,
      discovery: connections_message,
      total_connections: total_connections,
      all_keywords: all_keywords.uniq.first(10) # Show top 10 for display
    })
    
    sleep(0.5)
  end

  # Extract keywords from Qloo entity for display
  def extract_qloo_keywords_for_display(entity)
    keywords = []
    
    # Get from properties
    if entity.dig('properties', 'keywords').is_a?(Array)
      keywords = entity['properties']['keywords'].map { |k| 
        k.is_a?(Hash) ? k['name'] : k.to_s 
      }.compact
    end
    
    # Get from tags if no keywords
    if keywords.empty? && entity['tags']&.any?
      keywords = entity['tags'].map { |tag| tag['name'] }.compact.first(8)
    end
    
    keywords.map(&:downcase).uniq
  end

  # Find keywords related to a user interest
  def find_related_keywords(user_interest, all_keywords)
    interest_lower = user_interest.downcase
    related = []
    
    # Exact matches
    exact_matches = all_keywords.select { |kw| kw.include?(interest_lower) }
    related.concat(exact_matches)
    
    # Semantic matches (simple keyword associations)
    semantic_matches = case interest_lower
    when /art|arte/
      all_keywords.select { |kw| kw.match?(/gallery|museo|exhibition|modern|contemporary/) }
    when /food|restaurant|gastrono/
      all_keywords.select { |kw| kw.match?(/cuisine|chef|dining|gourmet|local/) }
    when /bar|drink|cocktail/
      all_keywords.select { |kw| kw.match?(/mixology|craft|spirits|wine|beer/) }
    when /music|musique/
      all_keywords.select { |kw| kw.match?(/concert|jazz|electronic|indie|venue/) }
    when /culture|cultural/
      all_keywords.select { |kw| kw.match?(/heritage|traditional|historic|artistic/) }
    when /cinema|film/
      all_keywords.select { |kw| kw.match?(/director|indie|arthouse|festival/) }
    else
      # Generic cultural keywords
      all_keywords.select { |kw| kw.match?(/creative|artistic|cultural|authentic/) }
    end
    
    related.concat(semantic_matches)
    related.uniq.first(6) # Limit to 6 most relevant
  end
end
