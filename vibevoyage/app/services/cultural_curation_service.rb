# app/services/cultural_curation_service.rb
class CulturalCurationService
  include ApplicationHelper
  
  class << self
    # Main curation method
    def curate_experiences(parsed_vibe, qloo_data)
      city = parsed_vibe[:city]
      language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
      qloo_entities = qloo_data&.dig('results', 'entities') || []
      
      Rails.logger.info "=== CURATING EXPERIENCES ==="
      Rails.logger.info "City: #{city}, Language: #{language}, Qloo entities: #{qloo_entities.size}"
      
      if qloo_entities.empty?
        Rails.logger.info "No Qloo data, using fallback experiences"
        return LocalizationService.generate_fallback_experiences(city, parsed_vibe[:interests], language)
      end

      experiences = qloo_entities.first(3).map.with_index do |qloo_entity, index|
        create_experience_from_qloo_entity(qloo_entity, parsed_vibe, index)
      end
      
      Rails.logger.info "✅ Curated #{experiences.size} experiences with Qloo data"
      experiences
    end

    # Enhanced Places data processing
    def process_places_data(parsed_vibe, qloo_data)
      city = parsed_vibe[:city]
      interests = parsed_vibe[:interests]
      
      Rails.logger.info "=== PROCESSING PLACES DATA ==="
      Rails.logger.info "City: #{city}, Interests: #{interests.inspect}"
      
      places_results = []
      
      if qloo_data && qloo_data.dig('results', 'entities')&.any?
        places_results = process_qloo_entities(qloo_data, city)
      else
        places_results = process_generic_search(interests, city)
      end
      
      # Fallback if no results
      if places_results.empty? || places_results.all? { |r| r[:google_data].nil? }
        Rails.logger.info "=== CREATING LLM FALLBACK ==="
        fallback_place = create_llm_fallback_place(city, interests.first)
        places_results << fallback_place if fallback_place
      end
      
      Rails.logger.info "=== FINAL PLACES RESULT ==="
      Rails.logger.info "Total places found: #{places_results.size}"
      places_results
    end

    # Calculate enhanced vibe match
    def calculate_vibe_match(qloo_entity, parsed_vibe, qloo_keywords = [])
      # Base score from Qloo popularity
      base_score = ((qloo_entity['popularity'] || 0.8).to_f * 100).round
      
      # Keyword matching bonus
      user_interests = parsed_vibe[:interests] || []
      keyword_matches = (user_interests & qloo_keywords).size
      keyword_bonus = keyword_matches * 10
      
      # Category matching bonus
      category_bonus = calculate_category_bonus(qloo_entity, user_interests)
      
      # Quality bonus based on rating
      quality_bonus = calculate_quality_bonus(qloo_entity)
      
      final_score = [base_score + keyword_bonus + category_bonus + quality_bonus, 100].min
      [final_score, 75].max # Minimum 75%
    end

    # Enhanced data extraction from Qloo entities
    def extract_enhanced_qloo_data(qloo_entity)
      entity_properties = qloo_entity['properties'] || {}
      entity_location = qloo_entity['location'] || {}
      entity_tags = qloo_entity['tags'] || []
      
      # Extract coordinates
      latitude = entity_location['lat']&.to_f
      longitude = entity_location['lon']&.to_f
      
      # Extract keywords more robustly
      qloo_keywords = extract_qloo_keywords(entity_properties, entity_tags)
      
      # Extract contact information
      contact_info = extract_contact_info(entity_properties)
      
      # Extract operational info
      operational_info = extract_operational_info(entity_properties)
      
      # Extract categorization
      categorization = extract_categorization_info(entity_tags)
      
      {
        coordinates: { latitude: latitude, longitude: longitude },
        keywords: qloo_keywords,
        contact: contact_info,
        operational: operational_info,
        categorization: categorization,
        raw_properties: entity_properties,
        raw_location: entity_location,
        raw_tags: entity_tags
      }
    end

    # Generate enhanced URLs and references
    def generate_enhanced_urls(latitude, longitude, place_name)
      return {} unless latitude && longitude
      
      {
        google_maps_url: "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}",
        directions_url: "https://www.google.com/maps/dir/?api=1&destination=#{latitude},#{longitude}",
        share_url: generate_share_url(latitude, longitude, place_name)
      }
    end

    # Calculate distance between coordinates
    def calculate_distance(lat1, lon1, lat2, lon2)
      return Float::INFINITY unless [lat1, lon1, lat2, lon2].all?(&:present?)
      
      rad_per_deg = Math::PI / 180
      rlat1 = lat1 * rad_per_deg
      rlat2 = lat2 * rad_per_deg
      dlat = rlat2 - rlat1
      dlon = (lon2 - lon1) * rad_per_deg
      
      a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlon/2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      
      6371 * c # Distance in kilometers
    end

    private

    def create_experience_from_qloo_entity(qloo_entity, parsed_vibe, index)
      language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
      
      # Extract enhanced data
      enhanced_data = extract_enhanced_qloo_data(qloo_entity)
      
      # Generate cultural explanation
      cultural_explanation = LlmService.generate_cultural_explanation(
        qloo_entity, 
        parsed_vibe, 
        enhanced_data[:keywords], 
        index
      )
      
      # Calculate vibe match
      vibe_match = calculate_vibe_match(qloo_entity, parsed_vibe, enhanced_data[:keywords])
      
      # Extract area intelligently
      area = extract_area_from_qloo_entity(qloo_entity, parsed_vibe[:city], language)
      
      # Generate URLs
      urls = generate_enhanced_urls(
        enhanced_data[:coordinates][:latitude],
        enhanced_data[:coordinates][:longitude],
        qloo_entity['name']
      )
      
      # Create experience hash
      {
        time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
        title: LocalizationService.experience_title(
          [:morning, :afternoon, :evening][index],
          [:discovery, :immersion, :culmination][index],
          language
        ),
        location: qloo_entity['name'],
        description: enhanced_data[:raw_properties]['description'] || 
                    enhanced_data[:raw_properties]['summary'] || 
                    generate_default_description(qloo_entity, language),
        cultural_explanation: cultural_explanation,
        duration: ["2 hours", "2.5 hours", "3 hours"][index],
        area: area,
        vibe_match: vibe_match,
        rating: enhanced_data[:operational][:rating],
        image: extract_image_url(enhanced_data[:raw_properties], index),
        
        # *** COMPLETE QLOO DATA ***
        qloo_keywords: enhanced_data[:keywords],
        qloo_entity_id: qloo_entity['entity_id'],
        qloo_popularity: qloo_entity['popularity'],
        
        # *** CONTACT INFORMATION ***
        website: enhanced_data[:contact][:website],
        phone: enhanced_data[:contact][:phone],
        address: enhanced_data[:contact][:address],
        
        # *** COORDINATES AND MAPS ***
        latitude: enhanced_data[:coordinates][:latitude],
        longitude: enhanced_data[:coordinates][:longitude],
        google_maps_url: urls[:google_maps_url],
        directions_url: urls[:directions_url],
        share_url: urls[:share_url],
        
        # *** OPERATIONAL INFORMATION ***
        hours: enhanced_data[:operational][:hours],
        price_level: enhanced_data[:operational][:price_level],
        price_range: generate_price_range(enhanced_data[:operational][:price_level]),
        
        # *** CATEGORIZATION ***
        tags: enhanced_data[:raw_tags],
        categories: enhanced_data[:categorization][:categories],
        amenities: enhanced_data[:categorization][:amenities],
        accessibility: enhanced_data[:categorization][:accessibility],
        family_friendly: enhanced_data[:categorization][:family_friendly],
        
        # *** ADDITIONAL INFO ***
        why_chosen: generate_why_chosen(qloo_entity, parsed_vibe, enhanced_data[:keywords], language),
        booking_info: enhanced_data[:operational][:booking_info]
      }
    end

    def process_qloo_entities(qloo_data, city)
      Rails.logger.info "=== PROCESSING QLOO ENTITIES ==="
      qloo_entities = qloo_data.dig('results', 'entities').first(3)
      
      places_results = []
      
      qloo_entities.each_with_index do |entity, index|
        place_name = entity['name']
        qloo_location = entity['location']
        
        Rails.logger.info "--- Processing entity #{index + 1}: #{place_name}"
        
        if qloo_location && qloo_location['lat'] && qloo_location['lon']
          coordinates = {
            'lat' => qloo_location['lat'].to_f,
            'lng' => qloo_location['lon'].to_f
          }
          
          # Try to enrich with Google Places (optional)
          google_data = try_enrich_with_google_places(place_name, city, coordinates) ||
                       create_google_data_from_qloo(entity, coordinates)
          
          places_results << {
            name: place_name,
            google_data: google_data,
            qloo_entity: entity
          }
        else
          # Fallback to Google Places search
          google_result = search_google_places_fallback(place_name, city)
          places_results << {
            name: place_name,
            google_data: google_result,
            qloo_entity: entity
          }
        end
      end
      
      places_results
    end

    def process_generic_search(interests, city)
      Rails.logger.info "=== PROCESSING GENERIC SEARCH ==="
      generic_queries = build_fallback_queries(interests, city)
      places_results = []
      
      generic_queries.each_with_index do |query, index|
        Rails.logger.info "--- Generic Query #{index + 1}: #{query}"
        
        begin
          google_result = RdawnApiService.google_places(query: query)
          
          if google_result[:success] && google_result[:data]&.dig('results')&.any?
            best_place = LlmService.find_best_place_match(
              google_result[:data]['results'].map { |place|
                {
                  name: place['name'],
                  address: place['formatted_address'],
                  rating: place['rating'],
                  types: place['types']&.join(', ')
                }
              },
              city
            )
            
            if best_place
              places_results << {
                name: best_place['name'],
                google_data: best_place,
                qloo_entity: nil
              }
            end
          end
        rescue => e
          Rails.logger.error "--- Generic search error: #{e.message}"
        end
      end
      
      places_results
    end

    def extract_qloo_keywords(entity_properties, entity_tags)
      qloo_keywords = []
      
      # Extract from properties keywords
      if entity_properties['keywords'].is_a?(Array)
        qloo_keywords = entity_properties['keywords'].map { |k| 
          k.is_a?(Hash) ? k['name'] : k.to_s 
        }.compact
      elsif entity_properties['keywords'].is_a?(String)
        qloo_keywords = entity_properties['keywords'].split(',').map(&:strip)
      end
      
      # Extract from tags if no keywords in properties
      if qloo_keywords.empty? && entity_tags.any?
        qloo_keywords = entity_tags.map { |tag| tag['name'] }.compact.first(10)
      end
      
      qloo_keywords
    end

    def extract_contact_info(entity_properties)
      {
        website: entity_properties['website'],
        phone: entity_properties['phone'],
        address: entity_properties['address']
      }
    end

    def extract_operational_info(entity_properties)
      {
        hours: entity_properties['hours'],
        price_level: entity_properties['price_level']&.to_i,
        rating: entity_properties['business_rating']&.to_f || 
               entity_properties['rating']&.to_f || 
               rand(4.0..5.0).round(1),
        booking_info: extract_booking_info(entity_properties)
      }
    end

    def extract_categorization_info(entity_tags)
      categories = []
      amenities = []
      accessibility = []
      family_friendly = []
      
      entity_tags.each do |tag|
        tag_name = tag['name']
        tag_type = tag['type']
        
        case tag_type
        when /category/i
          categories << tag_name
        when /amenity/i
          amenities << tag_name
        when /accessibility/i
          accessibility << tag_name
        end
        
        # Check for family-friendly indicators
        if tag_name.downcase.match?(/kid|family|children/)
          family_friendly << tag_name
        end
      end
      
      {
        categories: categories.uniq,
        amenities: amenities.uniq,
        accessibility: accessibility.any? ? accessibility : nil,
        family_friendly: family_friendly.any? ? family_friendly : nil
      }
    end

    def extract_booking_info(entity_properties)
      booking_info = {}
      
      %w[reservation_required booking_url advance_booking_recommended].each do |key|
        booking_info[key.to_sym] = entity_properties[key] if entity_properties[key]
      end
      
      booking_info.any? ? booking_info : nil
    end

    def calculate_category_bonus(qloo_entity, user_interests)
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
      
      category_bonus
    end

    def calculate_quality_bonus(qloo_entity)
      rating = qloo_entity.dig('properties', 'business_rating')&.to_f || 4.0
      case rating
      when 4.5..5.0 then 10
      when 4.0..4.4 then 5
      else 0
      end
    end

    def extract_area_from_qloo_entity(qloo_entity, city, language)
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
      
      valid_area || LocalizationService.localize('areas.center', language)
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

    def generate_share_url(latitude, longitude, place_name)
      encoded_name = CGI.escape(place_name || "")
      "https://maps.google.com/maps?q=#{latitude},#{longitude}&t=m&z=15&output=embed"
    end

    def extract_image_url(entity_properties, index)
      images = entity_properties['images'] || []
      
      if images.any?
        images.first.is_a?(Hash) ? images.first['url'] : images.first
      else
        get_fallback_image(index)
      end
    end

    def get_fallback_image(index)
      images = [
        "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
        "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3", 
        "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
      ]
      images[index] || images.first
    end

    def generate_default_description(qloo_entity, language)
      case language
      when 'es'
        "Una experiencia cultural única curada especialmente para tu vibe."
      when 'fr'
        "Une expérience culturelle unique curatée spécialement pour votre vibe."
      when 'pt'
        "Uma experiência cultural única curada especialmente para o seu vibe."
      when 'it'
        "Un'esperienza culturale unica curata appositamente per il tuo vibe."
      when 'de'
        "Eine einzigartige kulturelle Erfahrung, die speziell für Ihr Vibe kuratiert wurde."
      else
        "A unique cultural experience curated specifically for your vibe."
      end
    end

    def generate_why_chosen(qloo_entity, parsed_vibe, qloo_keywords, language)
      matching_keywords = (parsed_vibe[:interests] & qloo_keywords)
      popularity_score = ((qloo_entity['popularity'] || 0.8) * 100).round
      
      reasons = []
      
      if matching_keywords.any?
        case language
        when 'es'
          reasons << "Coincidencia directa con tus intereses: #{matching_keywords.join(', ')}"
        when 'fr'
          reasons << "Correspondance directe avec vos intérêts: #{matching_keywords.join(', ')}"
        when 'pt'
          reasons << "Correspondência direta com seus interesses: #{matching_keywords.join(', ')}"
        when 'it'
          reasons << "Corrispondenza diretta con i tuoi interessi: #{matching_keywords.join(', ')}"
        when 'de'
          reasons << "Direkte Übereinstimmung mit Ihren Interessen: #{matching_keywords.join(', ')}"
        else
          reasons << "Direct match with your interests: #{matching_keywords.join(', ')}"
        end
      end
      
      if popularity_score >= 80
        case language
        when 'es'
          reasons << "Alta popularidad cultural (#{popularity_score}%)"
        when 'fr'
          reasons << "Haute popularité culturelle (#{popularity_score}%)"
        when 'pt'
          reasons << "Alta popularidade cultural (#{popularity_score}%)"
        when 'it'
          reasons << "Alta popolarità culturale (#{popularity_score}%)"
        when 'de'
          reasons << "Hohe kulturelle Popularität (#{popularity_score}%)"
        else
          reasons << "High cultural popularity (#{popularity_score}%)"
        end
      end
      
      if qloo_keywords.any?
        top_keywords = qloo_keywords.first(3)
        case language
        when 'es'
          reasons << "Elementos culturales clave: #{top_keywords.join(', ')}"
        when 'fr'
          reasons << "Éléments culturels clés: #{top_keywords.join(', ')}"
        when 'pt'
          reasons << "Elementos culturais chave: #{top_keywords.join(', ')}"
        when 'it'
          reasons << "Elementi culturali chiave: #{top_keywords.join(', ')}"
        when 'de'
          reasons << "Wichtige kulturelle Elemente: #{top_keywords.join(', ')}"
        else
          reasons << "Key cultural elements: #{top_keywords.join(', ')}"
        end
      end
      
      if reasons.any?
        reasons.join('. ')
      else
        case language
        when 'es'
          "Curado especialmente para tu experiencia cultural única"
        when 'fr'
          "Curé spécialement pour votre expérience culturelle unique"
        when 'pt'
          "Curado especialmente para sua experiência cultural única"
        when 'it'
          "Curato appositamente per la tua esperienza culturale unica"
        when 'de'
          "Speziell für Ihre einzigartige kulturelle Erfahrung kuratiert"
        else
          "Curated specifically for your unique cultural experience"
        end
      end
    end

    # Helper methods for place processing
    def try_enrich_with_google_places(place_name, city, qloo_coordinates)
      # Implementation would go here - this is a placeholder
      nil
    end

    def create_google_data_from_qloo(entity, coordinates)
      {
        'name' => entity['name'],
        'formatted_address' => entity.dig('properties', 'address') || "#{entity['name']}",
        'geometry' => { 'location' => coordinates },
        'place_id' => entity['entity_id'] || "qloo_#{SecureRandom.hex(4)}",
        'rating' => entity.dig('properties', 'business_rating')&.to_f || 4.0,
        'types' => extract_types_from_qloo_entity(entity)
      }
    end

    def search_google_places_fallback(place_name, city)
      # Implementation would go here - this is a placeholder
      nil
    end

    def build_fallback_queries(interests, city)
      queries = []
      
      interests.each do |interest|
        case interest.downcase
        when /food|restaurant|soup/
          queries += ["restaurants #{city}", "traditional food #{city}"]
        when /bar|drink|tequila|mezcal/
          queries += ["bar #{city}", "cantina #{city}"]
        when /art|museum/
          queries += ["museum #{city}", "art gallery #{city}"]
        when /culture/
          queries += ["cultural center #{city}", "historic site #{city}"]
        else
          queries << "#{interest} #{city}"
        end
      end
      
      # Ensure we have at least 3 queries
      while queries.size < 3
        queries += ["historic center #{city}", "main square #{city}", "cultural attractions #{city}"]
      end
      
      queries.uniq.first(3)
    end

    def extract_types_from_qloo_entity(entity)
      tags = entity['tags'] || []
      types = []
      
      tags.each do |tag|
        tag_name = tag['name']&.downcase
        case tag_name
        when /hotel|hostel/ then types << 'lodging'
        when /restaurant/ then types << 'restaurant'
        when /bar/ then types << 'bar'
        when /museum/ then types << 'museum'
        when /park/ then types << 'park'
        end
      end
      
      types << 'point_of_interest' if types.empty?
      types << 'establishment'
      types.uniq
    end

    def create_llm_fallback_place(city, interest)
      coord_data = LlmService.generate_fallback_coordinates(city, interest)
      
      {
        name: coord_data[:place_name],
        google_data: {
          'name' => coord_data[:place_name],
          'formatted_address' => "Center, #{city}",
          'geometry' => {
            'location' => { 
              'lat' => coord_data[:latitude], 
              'lng' => coord_data[:longitude] 
            }
          },
          'place_id' => "fallback_#{city.downcase.gsub(' ', '_')}",
          'rating' => 4.2
        },
        qloo_entity: nil
      }
    end
  end
end