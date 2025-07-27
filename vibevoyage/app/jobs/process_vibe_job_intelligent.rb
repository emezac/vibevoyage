# app/jobs/process_vibe_job_intelligent.rb
class ProcessVibeJobIntelligent < ApplicationJob
  queue_as :default

def perform(process_id, user_vibe)
  puts "=== STARTING ProcessVibeJobIntelligent ==="
  puts "Process ID: #{process_id}"
  puts "User vibe: #{user_vibe}"
  
  begin
    # Step 1: Analysis with LLM (25%)
    update_status(process_id, 'analyzing', 'Analyzing your cultural essence...', 25)
    
    parsed_vibe = parse_vibe_with_rdawn(user_vibe, process_id)
    Rails.logger.info "--- Parsed Vibe from LLM: #{parsed_vibe.inspect}"
    
    # Step 2: Qloo API Query (50%)
    update_status(process_id, 'processing', 'Connecting to cultural databases...', 50)
    
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
    
    # Step 3: Intelligent curation with explanations (75%)
    update_status(process_id, 'curating', 'Curating experiences with cultural context...', 75)
    
    curated_experiences = curate_experiences_with_explanations(
      parsed_vibe, 
      recommendations_result[:data]
    )
    
    # Step 4: Build final narrative (90%)
    update_status(process_id, 'finalizing', 'Building your personalized narrative...', 90)
    
    narrative = build_intelligent_narrative(parsed_vibe, user_vibe, curated_experiences)
    
    # Step 5: Save to database with cultural explanations
    itinerary = save_intelligent_itinerary(user_vibe, parsed_vibe, narrative, curated_experiences)
    
    # *** FINAL RESULT UPDATED WITH ALL FIELDS ***
    user_language = parsed_vibe[:detected_language] || 'en'
    
    # Generate localized title
    adventure_title = case user_language
    when 'es' then "Tu Aventura en #{parsed_vibe[:city]}"
    when 'fr' then "Votre Aventure à #{parsed_vibe[:city]}"
    when 'pt' then "Sua Aventura em #{parsed_vibe[:city]}"
    when 'it' then "La Tua Avventura a #{parsed_vibe[:city]}"
    when 'de' then "Ihr Abenteuer in #{parsed_vibe[:city]}"
    else "Your Adventure in #{parsed_vibe[:city]}"
    end
    
    # Generate localized success message
    success_message = case user_language
    when 'es' then '¡Tu aventura cultural está lista!'
    when 'fr' then 'Votre aventure culturelle est prête!'
    when 'pt' then 'Sua aventura cultural está pronta!'
    when 'it' then 'La tua avventura culturale è pronta!'
    when 'de' then 'Ihr kulturelles Abenteuer ist bereit!'
    else 'Your cultural adventure is ready!'
    end
    
    final_result = {
      status: 'complete',
      message: success_message,
      progress: 100,
      itinerary: {
        id: itinerary.id,
        title: adventure_title,
        city: parsed_vibe[:city],
        narrative_html: narrative,
        experiences: curated_experiences.map.with_index do |exp, index|
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
            
            # *** MAIN QLOO DATA ***
            qloo_keywords: exp[:qloo_keywords] || [],
            qloo_entity_id: exp[:qloo_entity_id],
            qloo_popularity: exp[:qloo_popularity],
            why_chosen: exp[:why_chosen],
            
            # *** CONTACT AND LOCATION INFO ***
            website: exp[:website],
            phone: exp[:phone],
            address: exp[:address],
            latitude: exp[:latitude],
            longitude: exp[:longitude],
            google_maps_url: exp[:google_maps_url],
            directions_url: exp[:directions_url],
            
            # *** OPERATIONAL INFO ***
            hours: exp[:hours],
            price_level: exp[:price_level],
            price_range: exp[:price_range],
            
            # *** CATEGORIES AND FEATURES ***
            tags: exp[:tags] || [],
            categories: exp[:categories] || [],
            amenities: exp[:amenities] || [],
            accessibility: exp[:accessibility],
            family_friendly: exp[:family_friendly],
            
            # *** ADDITIONAL INFO ***
            booking_info: exp[:booking_info]
          }.compact  # Remove nil values
        end
      }
    }
    
    update_status(process_id, 'complete', success_message, 100, itinerary: final_result[:itinerary])
    
    Rails.logger.info "ProcessVibeJobIntelligent completed for process_id: #{process_id}"
    Rails.logger.info "--- Total fields per experience: #{final_result[:itinerary][:experiences].first&.keys&.size || 0}"
    Rails.logger.info "--- Experiences with coordinates: #{final_result[:itinerary][:experiences].count { |e| e[:latitude] && e[:longitude] }}"
    Rails.logger.info "--- Experiences with website: #{final_result[:itinerary][:experiences].count { |e| e[:website] }}"
    
  rescue => e
    puts "=== ERROR in ProcessVibeJobIntelligent: #{e.message} ==="
    Rails.logger.error "ProcessVibeJobIntelligent failed: #{e.message}\n#{e.backtrace.join("\n")}"
    
    # *** IMPROVE FALLBACK ***
    begin
      puts "=== Attempting fallback response ==="
      update_status(process_id, 'processing', 'Creating fallback experience...', 75)
      
      # Parse vibe with simpler method
      parsed_vibe = simple_vibe_parsing(user_vibe)
      
      # Create fallback experiences
      fallback_experiences = create_comprehensive_fallback(parsed_vibe)
      
      # Create simple narrative
      fallback_narrative = create_fallback_narrative(parsed_vibe, user_vibe)
      
      # Save fallback itinerary
      fallback_itinerary = save_fallback_itinerary(user_vibe, parsed_vibe, fallback_narrative, fallback_experiences)
      
      # Create final result with same enhanced structure
      user_language = parsed_vibe[:detected_language] || 'en'
      
      # Generate localized fallback title
      fallback_title = case user_language
      when 'es' then "Tu Aventura en #{parsed_vibe[:city]}"
      when 'fr' then "Votre Aventure à #{parsed_vibe[:city]}"
      when 'pt' then "Sua Aventura em #{parsed_vibe[:city]}"
      when 'it' then "La Tua Avventura a #{parsed_vibe[:city]}"
      when 'de' then "Ihr Abenteuer in #{parsed_vibe[:city]}"
      else "Your Adventure in #{parsed_vibe[:city]}"
      end
      
      # Generate localized fallback message
      fallback_message = case user_language
      when 'es' then '¡Tu aventura está lista! (Modo offline)'
      when 'fr' then 'Votre aventure est prête! (Mode hors ligne)'
      when 'pt' then 'Sua aventura está pronta! (Modo offline)'
      when 'it' then 'La tua avventura è pronta! (Modalità offline)'
      when 'de' then 'Ihr Abenteuer ist bereit! (Offline-Modus)'
      else 'Your adventure is ready! (Offline mode)'
      end
      
      final_result = {
        status: 'complete',
        message: fallback_message,
        progress: 100,
        itinerary: {
          id: fallback_itinerary.id,
          title: fallback_title,
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
      
      update_status(process_id, 'complete', fallback_message, 100, itinerary: final_result[:itinerary])
      puts "✅ Fallback response created successfully with enhanced data structure"
      
    rescue => fallback_error
      puts "=== FALLBACK ALSO FAILED: #{fallback_error.message} ==="
      update_status(process_id, 'failed', "Error processing your vibe: #{e.message}", 100)
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
      # First detect the language of the user input
      detected_language = detect_user_language(user_vibe)
      puts "=== DETECTED LANGUAGE: #{detected_language} ==="
      
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
      
      parsed_data = extract_json_from_llm_response(llm_response_json).deep_symbolize_keys
      # Add detected language to parsed data
      parsed_data[:detected_language] = detected_language
      
      return parsed_data
      
    rescue => e
      Rails.logger.error "Error in workflow parsing: #{e.message}"
      return parse_vibe_directly_with_llm(user_vibe)
    end
  end

  def parse_vibe_directly_with_llm(user_vibe)
    puts "=== Using direct LLM for parsing ==="
    
    # Detect language first
    detected_language = detect_user_language(user_vibe)
    puts "=== DETECTED LANGUAGE: #{detected_language} ==="
    
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
    parsed_data = extract_json_from_llm_response(llm_response).deep_symbolize_keys
    # Add detected language
    parsed_data[:detected_language] = detected_language
    
    parsed_data
  end

  def extract_json_from_llm_response(response_text)
    cleaned_text = response_text.strip.gsub(/^```json\n?/, '').gsub(/\n?```$/, '')
    JSON.parse(cleaned_text)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse LLM response: #{cleaned_text}"
    raise e
  end

  def detect_user_language(user_text)
    prompt = <<-PROMPT.strip
      Detect the language of this text and respond with only the language code.
      
      Possible languages:
      - "es" for Spanish
      - "en" for English  
      - "fr" for French
      - "pt" for Portuguese
      - "it" for Italian
      - "de" for German
      
      Text: "#{user_text}"
      
      Respond with only the 2-letter language code (e.g., "es", "en", "fr"):
    PROMPT

    begin
      llm_interface = Rdawn::LLMInterface.new(api_key: ENV['OPENAI_API_KEY'])
      task = Rdawn::Task.new(
        task_id: "detect_lang_#{SecureRandom.hex(4)}",
        name: "Detect User Language",
        is_llm_task: true,
        input_data: { prompt: prompt }
      )
      
      workflow = Rdawn::Workflow.new(workflow_id: "language_detector", name: "Language Detector")
      workflow.add_task(task)
      
      agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
      result = agent.run
      
      detected_lang = result.tasks.values.first.output_data[:llm_response].strip.downcase
      
      # Validate the detected language
      valid_languages = ['es', 'en', 'fr', 'pt', 'it', 'de']
      if valid_languages.include?(detected_lang)
        puts "--- Language detected: #{detected_lang}"
        return detected_lang
      else
        puts "--- Invalid language detected (#{detected_lang}), defaulting to 'en'"
        return 'en'
      end
      
    rescue => e
      puts "--- Error detecting language: #{e.message}, defaulting to 'en'"
      Rails.logger.error "Language detection failed: #{e.message}"
      return 'en' # Default to English
    end
  end

  # *** HYBRID FUNCTION: Use Qloo coordinates + Google Places for enrichment ***
  def fetch_google_places_data(parsed_vibe, qloo_data)
    city = parsed_vibe[:city]
    interests = parsed_vibe[:interests]
    
    puts "=== PROCESSING QLOO DATA WITH OPTIONAL ENRICHMENT ==="
    puts "City: #{city}"
    puts "Interests: #{interests.inspect}"
    puts "Qloo data present: #{qloo_data&.dig('results', 'entities')&.any? || false}"
    
    places_results = []
    
    # If we have Qloo data, use that data as base
    if qloo_data && qloo_data.dig('results', 'entities')&.any?
      puts "=== USING QLOO COORDINATES + GOOGLE PLACES DATA ==="
      qloo_entities = qloo_data.dig('results', 'entities').first(3)
      
      qloo_entities.each_with_index do |entity, index|
        place_name = entity['name']
        qloo_location = entity['location']
        qloo_address = entity.dig('properties', 'address')
        
        puts "--- Processing entity #{index + 1}: #{place_name}"
        puts "--- Qloo coordinates: #{qloo_location.inspect}"
        
        # Use Qloo coordinates as primary source
        if qloo_location && qloo_location['lat'] && qloo_location['lon']
          coordinates = {
            'lat' => qloo_location['lat'].to_f,
            'lng' => qloo_location['lon'].to_f
          }
          
          # Try to enrich with Google Places data (optional)
          google_data = try_enrich_with_google_places(place_name, city, coordinates)
          
          # If Google Places doesn't work, use Qloo data
          final_google_data = google_data || create_google_data_from_qloo(entity, coordinates)
          
          puts "--- ✅ USING QLOO COORDS: #{place_name} - Coords: #{coordinates.inspect}"
          
          places_results << {
            name: place_name,
            google_data: final_google_data,
            qloo_entity: entity
          }
        else
          puts "--- ❌ No coordinates in Qloo for: #{place_name}, searching in Google..."
          
          # Only search in Google Places if Qloo doesn't have coordinates
          google_result = search_in_google_places_fallback(place_name, city)
          
          places_results << {
            name: place_name,
            google_data: google_result,
            qloo_entity: entity
          }
        end
      end
    else
      # Fallback: search for generic places when no Qloo data
      puts "=== NO QLOO DATA - USING GENERIC SEARCH ==="
      generic_queries = build_fallback_queries(interests, city)
      
      generic_queries.each_with_index do |query, index|
        puts "--- Generic Query #{index + 1}: #{query}"
        
        begin
          google_result = RdawnApiService.google_places(query: query)
          
          if google_result[:success] && google_result[:data]&.dig('results')&.any?
            best_place = find_best_matching_place(google_result[:data]['results'], city)
            
            if best_place
              coordinates = best_place.dig('geometry', 'location')
              puts "--- ✅ GENERIC PLACE FOUND: #{best_place['name']} - Coords: #{coordinates.inspect}"
              
              places_results << {
                name: best_place['name'],
                google_data: best_place,
                qloo_entity: nil
              }
            end
          end
        rescue => e
          puts "--- ❌ ERROR in generic search: #{e.message}"
        end
      end
    end
    
    # If we found nothing, create LLM fallback
    if places_results.empty? || places_results.all? { |r| r[:google_data].nil? }
      puts "=== CREATING LLM FALLBACK ==="
      fallback_place = create_fallback_place_with_coordinates(city, interests.first)
      places_results << fallback_place if fallback_place
    end
    
    puts "=== FINAL RESULT ==="
    puts "Total places found: #{places_results.size}"
    places_results.each_with_index do |result, index|
      coords = result[:google_data]&.dig('geometry', 'location')
      puts "#{index + 1}. #{result[:name]} - Coords: #{coords&.inspect || 'NO COORDINATES'}"
    end
    
    Rails.logger.info "--- Total places found: #{places_results.size}"
    places_results
  end

  # Function to create Google Places data from Qloo
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

  # Optional function to enrich with Google Places (may fail)
  def try_enrich_with_google_places(place_name, city, qloo_coordinates)
    puts "--- Trying to enrich #{place_name} with Google Places..."
    
    begin
      query = "#{place_name} #{city}"
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        results = google_result[:data]['results']
        
        # Find result that's close to Qloo coordinates
        best_match = results.find do |place|
          google_coords = place.dig('geometry', 'location')
          next false unless google_coords
          
          # Check if they're close (within ~1km)
          distance = calculate_distance(
            qloo_coordinates['lat'], qloo_coordinates['lng'],
            google_coords['lat'], google_coords['lng']
          )
          
          distance < 1.0 # Less than 1km difference
        end
        
        if best_match
          # Use Qloo coordinates but other Google data
          best_match['geometry']['location'] = qloo_coordinates
          puts "--- ✅ Enriched with Google Places: #{best_match['name']}"
          return best_match
        end
      end
      
      puts "--- Could not enrich with Google Places"
      return nil
      
    rescue => e
      puts "--- Error enriching with Google Places: #{e.message}"
      return nil
    end
  end

  # Function to calculate distance between coordinates
  def calculate_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rlat1 = lat1 * rad_per_deg
    rlat2 = lat2 * rad_per_deg
    dlat = rlat2 - rlat1
    dlon = (lon2 - lon1) * rad_per_deg
    
    a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlon/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    6371 * c # Distance in kilometers
  end

  # Function to extract place types based on Qloo tags
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

  # Fallback only when Qloo doesn't have coordinates
  def search_in_google_places_fallback(place_name, city)
    query = "#{place_name} #{city}"
    puts "--- Fallback Google search: #{query}"
    
    begin
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        best_place = find_best_matching_place(google_result[:data]['results'], city, place_name)
        puts "--- ✅ Fallback found: #{best_place['name']}" if best_place
        return best_place
      else
        puts "--- ❌ Not found in Google Places: #{query}"
        return nil
      end
    rescue => e
      puts "--- ❌ Error in Google fallback: #{e.message}"
      return nil
    end
  end

  # New function to create fallback place using LLM for coordinates
  def create_fallback_place_with_coordinates(city, interest)
    prompt = <<-PROMPT.strip
      I need approximate coordinates of the city center to create a fallback marker.
      
      City: #{city}
      User interest: #{interest}
      
      Provide:
      1. Latitude and longitude of the main historic/tourist center of #{city}
      2. An appropriate name for the place (e.g., "Cultural Center of [City]", "Main Square of [City]")
      
      Respond in JSON format:
      {
        "latitude": 00.0000,
        "longitude": 00.0000,
        "place_name": "Place name"
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
      place_name = coords_data['place_name'] || "Cultural Center of #{city}"
      
      puts "--- ✅ CREATING LLM FALLBACK: #{place_name} - Coords: {lat: #{latitude}, lng: #{longitude}}"
      
      {
        name: place_name,
        google_data: {
          'name' => place_name,
          'formatted_address' => "Center, #{city}",
          'geometry' => {
            'location' => { 'lat' => latitude, 'lng' => longitude }
          },
          'place_id' => "fallback_#{city.downcase.gsub(' ', '_')}",
          'rating' => 4.2
        },
        qloo_entity: nil
      }
      
    rescue => e
      puts "--- Error generating LLM fallback: #{e.message}"
      Rails.logger.error "--- Error generating fallback coordinates: #{e.message}"
      
      # Fallback of fallback - very basic coordinates
      {
        name: "Center of #{city}",
        google_data: {
          'name' => "Center of #{city}",
          'formatted_address' => "Center, #{city}",
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
    
    # Build more specific searches based on interests
    interests.each do |interest|
      case interest
      when /soup|restaurant|food/
        queries << "restaurants #{city}"
        queries << "traditional food #{city}"
        queries << "authentic restaurant #{city}"
      when /tequila|mezcal|bar|craft beer/
        queries << "bar #{city}"
        queries << "cantina #{city}"
        queries << "craft beer #{city}"
      when /art|museum/
        queries << "museum #{city}"
        queries << "art gallery #{city}"
        queries << "art museum #{city}"
      when /cinema|movie/
        queries << "cinema #{city}"
        queries << "movie theater #{city}"
        queries << "theater #{city}"
      when /culture/
        queries << "cultural center #{city}"
        queries << "historic site #{city}"
        queries << "cultural attraction #{city}"
      else
        queries << "#{interest} #{city}"
      end
    end
    
    # If no specific queries, use guaranteed generic terms
    if queries.empty?
      queries = [
        "restaurants #{city}",
        "tourist attractions #{city}",
        "places of interest #{city}"
      ]
    end
    
    # Ensure we always have at least 3 different queries
    while queries.size < 3
      queries += [
        "historic center #{city}",
        "main square #{city}",
        "cathedral #{city}",
        "park #{city}",
        "market #{city}"
      ]
    end
    
    puts "--- Generated queries: #{queries.uniq.first(3).inspect}"
    queries.uniq.first(3)
  end

  # New function to find best result using LLM
  def find_best_matching_place(results, target_city, place_name = nil)
    return nil if results.empty?
    
    puts "--- Evaluating #{results.size} results for city: #{target_city} and place: #{place_name}"
    
    # If only one result, use it directly
    if results.size == 1
      puts "--- Only one result, using it: #{results.first['name']}"
      return results.first
    end
    
    # Use LLM to find best match
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
      I need you to select the best place from this list based on the given criteria.

      SEARCH CRITERIA:
      - Target city: #{target_city}
      - Specific place searched: #{place_name || 'any relevant place'}

      AVAILABLE OPTIONS:
      #{places_data.map { |p| "#{p[:index]}. #{p[:name]} - #{p[:address]} (Rating: #{p[:rating]} | Types: #{p[:types]})" }.join("\n")}

      INSTRUCTIONS:
      1. Select the place that best matches the target city "#{target_city}"
      2. If there's a specific name "#{place_name}", prioritize places with similar names
      3. Consider geographic location (address should be in or near #{target_city})
      4. In case of tie, prefer the place with better rating
      5. Respond ONLY with the index number (0, 1, 2, etc.)

      RESPONSE (only the number):
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
      
      # Fallback: use first result
      puts "--- Using first result as fallback: #{results.first['name']}"
      return results.first
    end
  end

  def extract_area_from_google_data(google_data, city)
    return "Center" unless google_data&.dig('formatted_address')
    
    address = google_data['formatted_address']
    
    prompt = <<-PROMPT.strip
      Extract the area, neighborhood or district name from this address:
      
      Address: "#{address}"
      City: #{city}
      
      Instructions:
      - Extract ONLY the area/neighborhood/district name (e.g., "Roma Norte", "Historic Center", "Polanco")
      - Do NOT include postal codes, numbers, or the main city
      - If no specific area, respond "Center"
      - Respond in maximum 3 words
      
      Area:
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
      
      # Clean the response
      area = area.gsub(/['""]/, '').strip
      area = area.split(',').first&.strip || "Center"
      
      puts "--- LLM extracted area: '#{area}' from address: #{address}"
      area
      
    rescue => e
      puts "--- Error extracting area with LLM: #{e.message}"
      "Center"
    end
  end

  def calculate_vibe_match_with_google(qloo_entity, google_data, parsed_vibe)
    # Calculate match based on available data
    base_score = qloo_entity ? calculate_vibe_match(qloo_entity, parsed_vibe) : 75
    
    # Bonus for having Google Places data
    google_bonus = google_data ? 10 : 0
    
    # Bonus for high rating
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
    
    # Bonus for type relevance
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

  # Remove hardcoding functions
  def get_city_variations(city)
    # No longer need to hardcode variations
    [city]
  end

  def similar_names?(name1, name2)
    return false unless name1 && name2
    
    # Use LLM for smarter comparison if needed
    # For now, simple comparison
    name1.downcase.include?(name2.downcase) || name2.downcase.include?(name1.downcase)
  end

  def extract_area_from_google_data(google_data, city)
    # Extract area/district from Google Places address
    if google_data && google_data['formatted_address']
      address_parts = google_data['formatted_address'].split(',').map(&:strip)
      
      # Find area that's not the main city
      area_candidates = address_parts.reject do |part|
        part.downcase.include?(city.downcase) ||
        part.match?(/^\d/) || # No postal codes
        part.length < 3 ||    # No very short parts
        part.downcase.include?('mexico') ||
        part.downcase.include?('yuc') ||
        part.downcase.include?('n.l.')
      end
      
      # Return first valid part or default
      area_candidates.first || "Center"
    else
      # Fallback based on city
      case city
      when "Mérida"
        "Historic Center"
      when "Monterrey"
        "Center"
      when "Mexico City"
        "Roma Norte"
      else
        "District 1"
      end
    end
  end

  def calculate_vibe_match_with_google(qloo_entity, google_data, parsed_vibe)
    # Calculate match based on Qloo and Google data
    base_score = qloo_entity ? calculate_vibe_match(qloo_entity, parsed_vibe) : 85
    
    # Bonus for having Google Places data
    google_bonus = google_data ? 10 : 0
    
    # Bonus for high rating
    rating_bonus = if google_data&.dig('rating')
      rating = google_data['rating'].to_f
      rating >= 4.5 ? 5 : rating >= 4.0 ? 3 : 0
    else
      0
    end
    
    [base_score + google_bonus + rating_bonus, 100].min
  end

  # *** UPDATED FUNCTION: Curate with Google locations ***
def curate_experiences_with_explanations(parsed_vibe, qloo_data)
  puts "=== Curating experiences with cultural explanations ==="
  
  city = parsed_vibe[:city]
  qloo_entities = qloo_data&.dig('results', 'entities') || []
  
  puts "=== QLOO ENTITIES FOUND: #{qloo_entities.size} ==="
  qloo_entities.each_with_index do |entity, i|
    puts "Entity #{i+1}: #{entity['name']} - #{entity['entity_id']}"
  end
  
  if qloo_entities.empty?
    puts "=== No Qloo data, using fallback experiences ==="
    return create_fallback_experiences_with_explanations(parsed_vibe)
  end

  experiences = qloo_entities.first(3).map.with_index do |qloo_entity, index|
    puts "--- Processing experience #{index + 1}: #{qloo_entity['name']} ---"
    
    # Extract ALL Qloo data more completely
    entity_properties = qloo_entity['properties'] || {}
    entity_location = qloo_entity['location'] || {}
    entity_tags = qloo_entity['tags'] || []
    
    # Qloo coordinates (priority)
    latitude = entity_location['lat']&.to_f
    longitude = entity_location['lon']&.to_f
    
    # Extract Qloo keywords more robustly
    qloo_keywords = []
    if entity_properties['keywords'].is_a?(Array)
      qloo_keywords = entity_properties['keywords'].map { |k| k.is_a?(Hash) ? k['name'] : k.to_s }.compact
    elsif entity_properties['keywords'].is_a?(String)
      qloo_keywords = entity_properties['keywords'].split(',').map(&:strip)
    end
    
    # If no keywords in properties, extract from tags
    if qloo_keywords.empty? && entity_tags.any?
      qloo_keywords = entity_tags.map { |tag| tag['name'] }.compact.first(10)
    end
    
    puts "--- Extracted keywords: #{qloo_keywords.inspect}"
    
    # Extract complete contact information
    website = entity_properties['website']
    phone = entity_properties['phone']
    address = entity_properties['address']
    
    # Extract hours information
    hours = entity_properties['hours']
    
    # Extract price information
    price_level = entity_properties['price_level']&.to_i
    
    # Extract rating
    rating = entity_properties['business_rating']&.to_f || 
             entity_properties['rating']&.to_f || 
             rand(4.0..5.0).round(1)
    
    # Extract more complete description
    description = entity_properties['description'] || 
                  entity_properties['summary'] || 
                  entity_properties['editorial_summary'] ||
                  "A unique cultural experience curated specifically for your vibe."
    
    # Extract images
    images = entity_properties['images'] || []
    main_image = if images.any?
      images.first.is_a?(Hash) ? images.first['url'] : images.first
    else
      get_experience_image(index)
    end
    
    # Generate cultural explanation using LLM
    cultural_explanation = generate_cultural_explanation(
      qloo_entity, 
      parsed_vibe, 
      qloo_keywords, 
      index
    )
    
    # Extract area more intelligently
    area = extract_area_from_qloo_entity(qloo_entity, city)
    
    # Calculate more sophisticated vibe match
    vibe_match = calculate_enhanced_vibe_match(qloo_entity, parsed_vibe, qloo_keywords)
    
    # Create experience with ALL data
    experience = {
      time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
      title: generate_localized_experience_title(qloo_entity, index, parsed_vibe[:detected_language] || 'en'),
      location: qloo_entity['name'],
      description: description,
      cultural_explanation: cultural_explanation,
      duration: ["2 hours", "2.5 hours", "3 hours"][index],
      area: area,
      vibe_match: vibe_match,
      rating: rating,
      image: main_image,
      
      # *** COMPLETE QLOO DATA ***
      qloo_keywords: qloo_keywords,
      qloo_entity_id: qloo_entity['entity_id'],
      qloo_popularity: qloo_entity['popularity'],
      
      # *** CONTACT INFORMATION ***
      website: website,
      phone: phone,
      address: address,
      
      # *** COORDINATES AND MAPS ***
      latitude: latitude,
      longitude: longitude,
      google_maps_url: generate_google_maps_url(latitude, longitude, qloo_entity['name']),
      directions_url: generate_directions_url(latitude, longitude),
      
      # *** OPERATIONAL INFORMATION ***
      hours: hours,
      price_level: price_level,
      price_range: generate_price_range(price_level),
      
      # *** TAGS AND CATEGORIES ***
      tags: entity_tags,
      categories: extract_categories_from_tags(entity_tags),
      amenities: extract_amenities_from_tags(entity_tags),
      
      # *** ADDITIONAL INFORMATION ***
      why_chosen: generate_enhanced_why_chosen(qloo_entity, parsed_vibe, qloo_keywords),
      booking_info: extract_booking_info(entity_properties),
      accessibility: extract_accessibility_info(entity_tags),
      family_friendly: extract_family_friendly_info(entity_tags),
      
      # *** RAW DATA FOR DEBUG ***
      qloo_raw_data: qloo_entity
    }
    
    puts "--- ✅ Experience #{index + 1} created with #{qloo_keywords.size} keywords and coordinates: #{latitude}, #{longitude}"
    puts "--- Website: #{website || 'N/A'}, Phone: #{phone || 'N/A'}"
    puts "--- Google Maps URL: #{experience[:google_maps_url]}"
    
    experience
  end
  
  puts "✅ Curated #{experiences.size} experiences with complete Qloo data"
  experiences
end

  def generate_cultural_explanation(entity, parsed_vibe, qloo_keywords, index)
    user_language = parsed_vibe[:detected_language] || 'en'
    
    # Language-specific prompts
    language_prompts = {
      'es' => {
        role: "Eres un curador cultural experto.",
        explanation: "Explica en un párrafo evocador (máximo 100 palabras) por qué este lugar es perfecto para #{index == 0 ? 'comenzar' : index == 1 ? 'continuar' : 'culminar'} su aventura cultural.",
        instructions: "Conecta los keywords de Qloo con la experiencia personal del usuario. Usa un tono cálido y poético. Responde solo con el párrafo explicativo."
      },
      'en' => {
        role: "You are an expert cultural curator.",
        explanation: "Explain in an evocative paragraph (maximum 100 words) why this place is perfect to #{index == 0 ? 'begin' : index == 1 ? 'continue' : 'culminate'} their cultural adventure.",
        instructions: "Connect Qloo keywords with the user's personal experience. Use a warm and poetic tone. Respond only with the explanatory paragraph."
      },
      'fr' => {
        role: "Vous êtes un curateur culturel expert.",
        explanation: "Expliquez dans un paragraphe évocateur (maximum 100 mots) pourquoi cet endroit est parfait pour #{index == 0 ? 'commencer' : index == 1 ? 'continuer' : 'culminer'} leur aventure culturelle.",
        instructions: "Connectez les mots-clés de Qloo avec l'expérience personnelle de l'utilisateur. Utilisez un ton chaleureux et poétique. Répondez seulement avec le paragraphe explicatif."
      },
      'pt' => {
        role: "Você é um curador cultural especialista.",
        explanation: "Explique em um parágrafo evocativo (máximo 100 palavras) por que este lugar é perfeito para #{index == 0 ? 'começar' : index == 1 ? 'continuar' : 'culminar'} sua aventura cultural.",
        instructions: "Conecte as palavras-chave do Qloo com a experiência pessoal do usuário. Use um tom caloroso e poético. Responda apenas com o parágrafo explicativo."
      },
      'it' => {
        role: "Sei un curatore culturale esperto.",
        explanation: "Spiega in un paragrafo evocativo (massimo 100 parole) perché questo posto è perfetto per #{index == 0 ? 'iniziare' : index == 1 ? 'continuare' : 'culminare'} la loro avventura culturale.",
        instructions: "Collega le parole chiave di Qloo con l'esperienza personale dell'utente. Usa un tono caldo e poetico. Rispondi solo con il paragrafo esplicativo."
      },
      'de' => {
        role: "Sie sind ein erfahrener Kulturkurator.",
        explanation: "Erklären Sie in einem eindringlichen Absatz (maximal 100 Wörter), warum dieser Ort perfekt ist, um #{index == 0 ? 'zu beginnen' : index == 1 ? 'fortzusetzen' : 'zu vollenden'} ihr kulturelles Abenteuer.",
        instructions: "Verbinden Sie Qloo-Schlüsselwörter mit der persönlichen Erfahrung des Benutzers. Verwenden Sie einen warmen und poetischen Ton. Antworten Sie nur mit dem erklärenden Absatz."
      }
    }
    
    # Get language-specific strings or default to English
    lang_strings = language_prompts[user_language] || language_prompts['en']
    
    prompt = <<-PROMPT.strip
      #{lang_strings[:role]}

      #{user_language == 'es' ? 'Usuario busca' : user_language == 'fr' ? 'L\'utilisateur cherche' : user_language == 'pt' ? 'Usuário busca' : user_language == 'it' ? 'L\'utente cerca' : user_language == 'de' ? 'Benutzer sucht' : 'User seeks'}: #{parsed_vibe[:interests].join(', ')} #{user_language == 'es' ? 'en' : user_language == 'fr' ? 'à' : user_language == 'pt' ? 'em' : user_language == 'it' ? 'a' : user_language == 'de' ? 'in' : 'in'} #{parsed_vibe[:city]}
      #{user_language == 'es' ? 'Lugar' : user_language == 'fr' ? 'Lieu' : user_language == 'pt' ? 'Local' : user_language == 'it' ? 'Posto' : user_language == 'de' ? 'Ort' : 'Place'}: #{entity['name']}
      #{user_language == 'es' ? 'Descripción' : user_language == 'fr' ? 'Description' : user_language == 'pt' ? 'Descrição' : user_language == 'it' ? 'Descrizione' : user_language == 'de' ? 'Beschreibung' : 'Description'}: #{entity.dig('properties', 'description') || entity.dig('properties', 'summary')}
      #{user_language == 'es' ? 'Keywords culturales' : user_language == 'fr' ? 'Mots-clés culturels' : user_language == 'pt' ? 'Palavras-chave culturais' : user_language == 'it' ? 'Parole chiave culturali' : user_language == 'de' ? 'Kulturelle Schlüsselwörter' : 'Cultural keywords'}: #{qloo_keywords.join(', ')}
      
      #{lang_strings[:explanation]}
      
      #{lang_strings[:instructions]}
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
      explanation.strip.gsub(/^["']|["']$/, '') # Clean quotes
      
    rescue => e
      puts "❌ Error generating cultural explanation: #{e.message}"
      # Fallback in user's language
      fallback_messages = {
        'es' => "Este lugar conecta perfectamente con tu búsqueda de #{parsed_vibe[:interests].join(' y ')} en #{parsed_vibe[:city]}.",
        'en' => "This place connects perfectly with your search for #{parsed_vibe[:interests].join(' and ')} in #{parsed_vibe[:city]}.",
        'fr' => "Cet endroit se connecte parfaitement avec votre recherche de #{parsed_vibe[:interests].join(' et ')} à #{parsed_vibe[:city]}.",
        'pt' => "Este lugar se conecta perfeitamente com sua busca por #{parsed_vibe[:interests].join(' e ')} em #{parsed_vibe[:city]}.",
        'it' => "Questo posto si collega perfettamente con la tua ricerca di #{parsed_vibe[:interests].join(' e ')} a #{parsed_vibe[:city]}.",
        'de' => "Dieser Ort verbindet sich perfekt mit Ihrer Suche nach #{parsed_vibe[:interests].join(' und ')} in #{parsed_vibe[:city]}."
      }
      fallback_messages[user_language] || fallback_messages['en']
    end
  end

  def generate_experience_title(entity, index)
    # This will be called with parsed_vibe, so we need to update the calling function
    # For now, keeping English titles since this is called without language context
    time_prefixes = ["Morning:", "Afternoon:", "Evening:"]
    descriptors = ["Cultural Discovery", "Authentic Immersion", "Perfect Culmination"]
    
    "#{time_prefixes[index]} #{descriptors[index]}"
  end

  def generate_localized_experience_title(entity, index, user_language)
    titles = case user_language
    when 'es'
      {
        time_prefixes: ["Mañana:", "Tarde:", "Noche:"],
        descriptors: ["Descubrimiento Cultural", "Inmersión Auténtica", "Culminación Perfecta"]
      }
    when 'fr'
      {
        time_prefixes: ["Matin:", "Après-midi:", "Soir:"],
        descriptors: ["Découverte Culturelle", "Immersion Authentique", "Culmination Parfaite"]
      }
    when 'pt'
      {
        time_prefixes: ["Manhã:", "Tarde:", "Noite:"],
        descriptors: ["Descoberta Cultural", "Imersão Autêntica", "Culminação Perfeita"]
      }
    when 'it'
      {
        time_prefixes: ["Mattina:", "Pomeriggio:", "Sera:"],
        descriptors: ["Scoperta Culturale", "Immersione Autentica", "Culminazione Perfetta"]
      }
    when 'de'
      {
        time_prefixes: ["Morgen:", "Nachmittag:", "Abend:"],
        descriptors: ["Kulturelle Entdeckung", "Authentische Immersion", "Perfekte Kulmination"]
      }
    else # Default to English
      {
        time_prefixes: ["Morning:", "Afternoon:", "Evening:"],
        descriptors: ["Cultural Discovery", "Authentic Immersion", "Perfect Culmination"]
      }
    end
    
    "#{titles[:time_prefixes][index]} #{titles[:descriptors][index]}"
  end

  def generate_why_chosen(entity, parsed_vibe, qloo_keywords)
    # Brief reason why this place was chosen
    matching_keywords = (parsed_vibe[:interests] & qloo_keywords).any? ? 
      "Direct match with your interests" : 
      "Perfectly complements your cultural search"
    
    "#{matching_keywords}. #{qloo_keywords.first(3).join(', ')}"
  end

  def create_fallback_experiences_with_explanations(parsed_vibe)
    city = parsed_vibe[:city] || 'your destination'
    interests = parsed_vibe[:interests].join(', ')
    user_language = parsed_vibe[:detected_language] || 'en'
    
    # Language-specific content
    content = case user_language
    when 'es'
      {
        titles: ["Mañana: Descubrimiento Local", "Tarde: Experiencia Auténtica", "Noche: Culminación Cultural"],
        locations: ["Centro Cultural de #{city}", "Restaurante Tradicional", "Espacio Cultural Nocturno"],
        descriptions: [
          "Comienza explorando el corazón cultural de #{city}.",
          "Una pausa gastronómica que conecta con la tradición local.",
          "Cierra tu día en un ambiente que captura la esencia nocturna de #{city}."
        ],
        explanations: [
          "Este lugar representa la esencia cultural de #{city}, perfectamente alineado con tu búsqueda de #{interests}.",
          "La gastronomía local es una ventana al alma de #{city}, y este lugar encarna esa esencia.",
          "La noche revela otra faceta de #{city}, y este lugar es el epítome de esa transformación cultural."
        ],
        areas: ["Centro", "Distrito Histórico", "Zona de Entretenimiento"],
        why_chosen: [
          "Seleccionado por su relevancia cultural en #{city}",
          "Elegido por su autenticidad gastronómica",
          "Perfecto para culminar tu jornada cultural"
        ]
      }
    when 'fr'
      {
        titles: ["Matin: Découverte Locale", "Après-midi: Expérience Authentique", "Soir: Culmination Culturelle"],
        locations: ["Centre Culturel de #{city}", "Restaurant Traditionnel", "Espace Culturel Nocturne"],
        descriptions: [
          "Commencez en explorant le cœur culturel de #{city}.",
          "Une pause gastronomique qui se connecte à la tradition locale.",
          "Terminez votre journée dans une atmosphère qui capture l'essence nocturne de #{city}."
        ],
        explanations: [
          "Cet endroit représente l'essence culturelle de #{city}, parfaitement aligné avec votre recherche de #{interests}.",
          "La gastronomie locale est une fenêtre sur l'âme de #{city}, et cet endroit incarne cette essence.",
          "La nuit révèle une autre facette de #{city}, et cet endroit est l'épitome de cette transformation culturelle."
        ],
        areas: ["Centre", "District Historique", "Zone de Divertissement"],
        why_chosen: [
          "Sélectionné pour sa pertinence culturelle à #{city}",
          "Choisi pour son authenticité gastronomique",
          "Parfait pour culminer votre parcours culturel"
        ]
      }
    when 'pt'
      {
        titles: ["Manhã: Descoberta Local", "Tarde: Experiência Autêntica", "Noite: Culminação Cultural"],
        locations: ["Centro Cultural de #{city}", "Restaurante Tradicional", "Espaço Cultural Noturno"],
        descriptions: [
          "Comece explorando o coração cultural de #{city}.",
          "Uma pausa gastronômica que conecta com a tradição local.",
          "Termine seu dia em um ambiente que captura a essência noturna de #{city}."
        ],
        explanations: [
          "Este lugar representa a essência cultural de #{city}, perfeitamente alinhado com sua busca por #{interests}.",
          "A gastronomia local é uma janela para a alma de #{city}, e este lugar incorpora essa essência.",
          "A noite revela outra faceta de #{city}, e este lugar é o epítome dessa transformação cultural."
        ],
        areas: ["Centro", "Distrito Histórico", "Zona de Entretenimento"],
        why_chosen: [
          "Selecionado por sua relevância cultural em #{city}",
          "Escolhido por sua autenticidade gastronômica",
          "Perfeito para culminar sua jornada cultural"
        ]
      }
    when 'it'
      {
        titles: ["Mattina: Scoperta Locale", "Pomeriggio: Esperienza Autentica", "Sera: Culminazione Culturale"],
        locations: ["Centro Culturale di #{city}", "Ristorante Tradizionale", "Spazio Culturale Notturno"],
        descriptions: [
          "Inizia esplorando il cuore culturale di #{city}.",
          "Una pausa gastronomica che si collega alla tradizione locale.",
          "Chiudi la tua giornata in un'atmosfera che cattura l'essenza notturna di #{city}."
        ],
        explanations: [
          "Questo posto rappresenta l'essenza culturale di #{city}, perfettamente allineato con la tua ricerca di #{interests}.",
          "La gastronomia locale è una finestra sull'anima di #{city}, e questo posto incarna quell'essenza.",
          "La notte rivela un'altra sfaccettatura di #{city}, e questo posto è l'epitome di quella trasformazione culturale."
        ],
        areas: ["Centro", "Distretto Storico", "Zona di Intrattenimento"],
        why_chosen: [
          "Selezionato per la sua rilevanza culturale a #{city}",
          "Scelto per la sua autenticità gastronomica",
          "Perfetto per culminare il tuo percorso culturale"
        ]
      }
    when 'de'
      {
        titles: ["Morgen: Lokale Entdeckung", "Nachmittag: Authentische Erfahrung", "Abend: Kulturelle Kulmination"],
        locations: ["Kulturzentrum von #{city}", "Traditionelles Restaurant", "Nächtlicher Kulturraum"],
        descriptions: [
          "Beginnen Sie mit der Erkundung des kulturellen Herzens von #{city}.",
          "Eine gastronomische Pause, die sich mit der lokalen Tradition verbindet.",
          "Beenden Sie Ihren Tag in einer Atmosphäre, die die nächtliche Essenz von #{city} einfängt."
        ],
        explanations: [
          "Dieser Ort repräsentiert die kulturelle Essenz von #{city}, perfekt abgestimmt auf Ihre Suche nach #{interests}.",
          "Die lokale Gastronomie ist ein Fenster zur Seele von #{city}, und dieser Ort verkörpert diese Essenz.",
          "Die Nacht offenbart eine andere Facette von #{city}, und dieser Ort ist der Inbegriff dieser kulturellen Transformation."
        ],
        areas: ["Zentrum", "Historisches Viertel", "Unterhaltungszone"],
        why_chosen: [
          "Ausgewählt für seine kulturelle Relevanz in #{city}",
          "Gewählt für seine gastronomische Authentizität",
          "Perfekt, um Ihre kulturelle Reise zu vollenden"
        ]
      }
    else # Default to English
      {
        titles: ["Morning: Local Discovery", "Afternoon: Authentic Experience", "Evening: Cultural Culmination"],
        locations: ["Cultural Center of #{city}", "Traditional Restaurant", "Nocturnal Cultural Space"],
        descriptions: [
          "Begin exploring the cultural heart of #{city}.",
          "A gastronomic pause that connects with local tradition.",
          "Close your day in an atmosphere that captures the nocturnal essence of #{city}."
        ],
        explanations: [
          "This place represents the cultural essence of #{city}, perfectly aligned with your search for #{interests}.",
          "Local gastronomy is a window to the soul of #{city}, and this place embodies that essence.",
          "The night reveals another facet of #{city}, and this place is the epitome of that cultural transformation."
        ],
        areas: ["Center", "Historic District", "Entertainment Zone"],
        why_chosen: [
          "Selected for its cultural relevance in #{city}",
          "Chosen for its gastronomic authenticity",
          "Perfect to culminate your cultural journey"
        ]
      }
    end
    
    [
      {
        time: "10:00 AM",
        title: content[:titles][0],
        location: content[:locations][0],
        description: content[:descriptions][0],
        cultural_explanation: content[:explanations][0],
        duration: "2 hours",
        area: content[:areas][0],
        vibe_match: 85,
        rating: 4.2,
        image: get_experience_image(0),
        qloo_keywords: [],
        why_chosen: content[:why_chosen][0]
      },
      {
        time: "02:00 PM",
        title: content[:titles][1],
        location: content[:locations][1],
        description: content[:descriptions][1],
        cultural_explanation: content[:explanations][1],
        duration: "2.5 hours",
        area: content[:areas][1],
        vibe_match: 88,
        rating: 4.4,
        image: get_experience_image(1),
        qloo_keywords: [],
        why_chosen: content[:why_chosen][1]
      },
      {
        time: "07:30 PM",
        title: content[:titles][2],
        location: content[:locations][2],
        description: content[:descriptions][2],
        cultural_explanation: content[:explanations][2],
        duration: "3 hours",
        area: content[:areas][2],
        vibe_match: 82,
        rating: 4.1,
        image: get_experience_image(2),
        qloo_keywords: [],
        why_chosen: content[:why_chosen][2]
      }
    ]
  end

  def build_intelligent_narrative(parsed_vibe, user_vibe, experiences)
    city = parsed_vibe[:city]
    interests = parsed_vibe[:interests].join(', ')
    user_language = parsed_vibe[:detected_language] || 'en'
    
    # Language-specific content
    content = case user_language
    when 'es'
      {
        title: "🌟 Tu Aventura Cultural en #{city}",
        original_vibe: "Tu vibe original:",
        destination: "Destino Identificado",
        interests_label: "Intereses Detectados", 
        curation: "Curación Inteligente",
        description: "Usando datos culturales de Qloo API y análisis de IA, hemos diseñado #{experiences.size} experiencias que capturan la esencia de #{city} y resuenan con tu búsqueda personal."
      }
    when 'fr'
      {
        title: "🌟 Votre Aventure Culturelle à #{city}",
        original_vibe: "Votre vibe original:",
        destination: "Destination Identifiée",
        interests_label: "Intérêts Détectés",
        curation: "Curation Intelligente", 
        description: "En utilisant les données culturelles de l'API Qloo et l'analyse IA, nous avons conçu #{experiences.size} expériences qui capturent l'essence de #{city} et résonnent avec votre recherche personnelle."
      }
    when 'pt'
      {
        title: "🌟 Sua Aventura Cultural em #{city}",
        original_vibe: "Seu vibe original:",
        destination: "Destino Identificado",
        interests_label: "Interesses Detectados",
        curation: "Curadoria Inteligente",
        description: "Usando dados culturais da API Qloo e análise de IA, projetamos #{experiences.size} experiências que capturam a essência de #{city} e ressoam com sua busca pessoal."
      }
    when 'it'
      {
        title: "🌟 La Tua Avventura Culturale a #{city}",
        original_vibe: "Il tuo vibe originale:",
        destination: "Destinazione Identificata", 
        interests_label: "Interessi Rilevati",
        curation: "Curazione Intelligente",
        description: "Utilizzando i dati culturali dell'API Qloo e l'analisi AI, abbiamo progettato #{experiences.size} esperienze che catturano l'essenza di #{city} e risuonano con la tua ricerca personale."
      }
    when 'de'
      {
        title: "🌟 Ihr Kulturelles Abenteuer in #{city}",
        original_vibe: "Ihr ursprüngliches Vibe:",
        destination: "Identifiziertes Ziel",
        interests_label: "Erkannte Interessen",
        curation: "Intelligente Kuration", 
        description: "Mit kulturellen Daten aus der Qloo-API und KI-Analyse haben wir #{experiences.size} Erfahrungen entworfen, die die Essenz von #{city} erfassen und mit Ihrer persönlichen Suche in Resonanz stehen."
      }
    else # Default to English
      {
        title: "🌟 Your Cultural Adventure in #{city}",
        original_vibe: "Your original vibe:",
        destination: "Identified Destination",
        interests_label: "Detected Interests",
        curation: "Intelligent Curation",
        description: "Using Qloo API cultural data and AI analysis, we've designed #{experiences.size} experiences that capture the essence of #{city} and resonate with your personal search."
      }
    end
    
    <<~HTML
      <div class="narrative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-8 rounded-2xl">
        <h2 class="text-3xl font-bold mb-6 gradient-text">#{content[:title]}</h2>
        
        <div class="glass-card p-6 mb-6">
          <p class="text-lg text-slate-300 mb-4">
            <strong class="text-white">#{content[:original_vibe]}</strong> 
            <em>"#{user_vibe}"</em>
          </p>
        </div>
        
        <div class="grid md:grid-cols-2 gap-6 mb-6">
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
              📍 <span style="color: var(--accent-terracotta);">#{content[:destination]}</span>
            </h3>
            <p class="text-slate-300">#{city}</p>
          </div>
          
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
              🎯 <span style="color: var(--accent-sage);">#{content[:interests_label]}</span>
            </h3>
            <p class="text-slate-300">#{interests}</p>
          </div>
        </div>
        
        <div class="glass-card p-6">
          <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
            ✨ <span style="color: var(--accent-gold);">#{content[:curation]}</span>
          </h3>
          <p class="text-slate-300">
            #{content[:description]}
          </p>
        </div>
      </div>
    HTML
  end

# Replace the save_intelligent_itinerary method in ProcessVibeJobIntelligent

def save_intelligent_itinerary(user_vibe, parsed_vibe, narrative, experiences)
  city = parsed_vibe[:city] || 'Unknown City'
  preferences = parsed_vibe[:preferences]&.join(', ') || 'various preferences'
  user_language = parsed_vibe[:detected_language] || 'en'
  
  # Generate localized itinerary name
  itinerary_name = case user_language
  when 'es' then "Aventura Cultural en #{city}"
  when 'fr' then "Aventure Culturelle à #{city}"
  when 'pt' then "Aventura Cultural em #{city}"
  when 'it' then "Avventura Culturale a #{city}"
  when 'de' then "Kulturelles Abenteuer in #{city}"
  else "Cultural Adventure in #{city}"
  end
  
  itinerary = Itinerary.create!(
    user_id: 1,
    description: user_vibe,
    city: city,
    location: city,
    name: itinerary_name,
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
      
      puts "✅ Enhanced stop created: #{exp[:location]} (ID: #{stop.id})"
      puts "   - Coords: #{exp[:latitude]}, #{exp[:longitude]}"
      puts "   - Website: #{exp[:website] || 'N/A'}"
      puts "   - Phone: #{exp[:phone] || 'N/A'}"
      puts "   - Keywords: #{exp[:qloo_keywords]&.size || 0}"
      
    rescue => e
      puts "❌ Error creating enhanced stop: #{e.message}"
      puts "=== Available columns: #{ItineraryStop.column_names.inspect}"
      
      # Fallback: try with minimal data
      begin
        minimal_attributes = {
          name: exp[:location],
          description: exp[:description],
          address: "#{exp[:area]}, #{city}"
        }
        
        minimal_attributes[:position] = index + 1 if column_names.include?('position')
        
        fallback_stop = itinerary.itinerary_stops.create!(minimal_attributes)
        puts "✅ Fallback stop created: #{exp[:location]} (ID: #{fallback_stop.id})"
        
      rescue => fallback_error
        puts "❌ Error in fallback stop: #{fallback_error.message}"
      end
    end
  end
  
  puts "✅ Enhanced itinerary saved with ID: #{itinerary.id}"
  puts "   - Experiences: #{experiences.size}"
  puts "   - Total keywords: #{experiences.sum { |e| e[:qloo_keywords]&.size || 0 }}"
  puts "   - Places with coordinates: #{experiences.count { |e| e[:latitude] && e[:longitude] }}"
  puts "   - Places with website: #{experiences.count { |e| e[:website] }}"
  puts "   - Places with phone: #{experiences.count { |e| e[:phone] }}"
  
  itinerary
end

  def calculate_vibe_match(entity, parsed_vibe)
    # Calculate match based on Qloo popularity and interest matches
    base_score = (entity['popularity'].to_f * 100).round
    
    # Bonus for keyword matches
    entity_keywords = entity.dig('properties', 'keywords') || []
    matches = (parsed_vibe[:interests] & entity_keywords).size
    bonus = matches * 5
    
    [[base_score + bonus, 95].min, 75].max
  end

  def extract_area_from_entity(entity, city)
    # Try to extract area from Qloo data
    area = entity.dig('properties', 'geocode', 'name') ||
           entity.dig('properties', 'address')&.split(',')&.first ||
           'Center'
    
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
  # Try to extract area from multiple Qloo sources
  area_candidates = [
    qloo_entity.dig('properties', 'geocode', 'name'),
    qloo_entity.dig('properties', 'neighborhood'),
    qloo_entity.dig('properties', 'district'),
    qloo_entity.dig('properties', 'area'),
    qloo_entity.dig('location', 'neighborhood'),
    qloo_entity.dig('properties', 'address')&.split(',')&.first
  ].compact.map(&:strip)
  
  # Filter valid candidates
  valid_area = area_candidates.find do |candidate|
    candidate.length > 2 && 
    !candidate.downcase.include?(city.downcase) &&
    !candidate.match?(/^\d+/) # No postal codes
  end
  
  valid_area || "Center"
end

  def generate_google_maps_url(latitude, longitude, place_name)
  return nil unless latitude && longitude
  
  # URL to open in Google Maps
  encoded_name = CGI.escape(place_name || "")
  "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}&query_place_id=#{encoded_name}"
end

def generate_directions_url(latitude, longitude)
  return nil unless latitude && longitude
  
  # URL to get directions
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
  # More detailed reason
  matching_keywords = (parsed_vibe[:interests] & qloo_keywords)
  popularity_score = ((qloo_entity['popularity'] || 0.8) * 100).round
  
  reasons = []
  
  if matching_keywords.any?
    reasons << "Direct match with your interests: #{matching_keywords.join(', ')}"
  end
  
  if popularity_score >= 80
    reasons << "High cultural popularity (#{popularity_score}%)"
  end
  
  if qloo_keywords.any?
    top_keywords = qloo_keywords.first(3)
    reasons << "Key cultural elements: #{top_keywords.join(', ')}"
  end
  
  reasons.any? ? reasons.join('. ') : "Curated specifically for your unique cultural experience"
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

  # Missing fallback methods that need to be added
  def simple_vibe_parsing(user_vibe)
    # Simple parsing fallback
    detected_language = detect_user_language(user_vibe)
    
    {
      city: extract_city_from_text(user_vibe),
      interests: extract_interests_from_text(user_vibe),
      preferences: ['culture', 'authentic'],
      detected_language: detected_language
    }
  end

  def extract_city_from_text(text)
    # Simple city extraction
    cities = ['Mexico City', 'Toronto', 'New York', 'London', 'Paris', 'Tokyo']
    cities.find { |city| text.downcase.include?(city.downcase) } || 'Mexico City'
  end

  def extract_interests_from_text(text)
    # Simple interest extraction
    interests = []
    interests << 'restaurant' if text.downcase.include?('food') || text.downcase.include?('restaurant')
    interests << 'bar' if text.downcase.include?('drink') || text.downcase.include?('bar')
    interests << 'museum' if text.downcase.include?('art') || text.downcase.include?('museum')
    interests << 'culture' if interests.empty?
    interests
  end

  def create_comprehensive_fallback(parsed_vibe)
    create_fallback_experiences_with_explanations(parsed_vibe)
  end

  def create_fallback_narrative(parsed_vibe, user_vibe)
    city = parsed_vibe[:city]
    user_language = parsed_vibe[:detected_language] || 'en'
    
    # Language-specific content
    content = case user_language
    when 'es'
      {
        title: "🌟 Tu Aventura Cultural en #{city}",
        original_vibe: "Tu vibe original:",
        description: "Hemos creado una experiencia cultural curada para ti en #{city} basada en tus preferencias."
      }
    when 'fr'
      {
        title: "🌟 Votre Aventure Culturelle à #{city}",
        original_vibe: "Votre vibe original:",
        description: "Nous avons créé une expérience culturelle curatée pour vous à #{city} basée sur vos préférences."
      }
    when 'pt'
      {
        title: "🌟 Sua Aventura Cultural em #{city}",
        original_vibe: "Seu vibe original:",
        description: "Criamos uma experiência cultural curada para você em #{city} baseada nas suas preferências."
      }
    when 'it'
      {
        title: "🌟 La Tua Avventura Culturale a #{city}",
        original_vibe: "Il tuo vibe originale:",
        description: "Abbiamo creato un'esperienza culturale curata per te a #{city} basata sulle tue preferenze."
      }
    when 'de'
      {
        title: "🌟 Ihr Kulturelles Abenteuer in #{city}",
        original_vibe: "Ihr ursprüngliches Vibe:",
        description: "Wir haben eine kuratierte kulturelle Erfahrung für Sie in #{city} basierend auf Ihren Präferenzen erstellt."
      }
    else # Default to English
      {
        title: "🌟 Your Cultural Adventure in #{city}",
        original_vibe: "Your original vibe:",
        description: "We've created a curated cultural experience for you in #{city} based on your preferences."
      }
    end
    
    <<~HTML
      <div class="narrative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-8 rounded-2xl">
        <h2 class="text-3xl font-bold mb-6 gradient-text">#{content[:title]}</h2>
        <div class="glass-card p-6 mb-6">
          <p class="text-lg text-slate-300 mb-4">
            <strong class="text-white">#{content[:original_vibe]}</strong> 
            <em>"#{user_vibe}"</em>
          </p>
        </div>
        <div class="glass-card p-6">
          <p class="text-slate-300">
            #{content[:description]}
          </p>
        </div>
      </div>
    HTML
  end

  def save_fallback_itinerary(user_vibe, parsed_vibe, narrative, experiences)
    save_intelligent_itinerary(user_vibe, parsed_vibe, narrative, experiences)
  end
end