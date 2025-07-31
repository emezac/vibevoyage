# app/services/places_enrichment_service.rb
class PlacesEnrichmentService
  include ApplicationHelper

  # Distance threshold for coordinate matching (in kilometers)
  COORDINATE_MATCH_THRESHOLD = 1.0
  
  # Cache settings
  CACHE_EXPIRES_IN = 2.hours
  
  class << self
    # Main method to process and enrich places data
    def process_places_data(parsed_vibe, qloo_data)
      city = parsed_vibe[:city]
      interests = parsed_vibe[:interests]
      
      Rails.logger.info "=== PROCESSING PLACES DATA ==="
      Rails.logger.info "City: #{city}, Interests: #{interests.inspect}"
      
      places_results = []
      
      if has_qloo_entities?(qloo_data)
        places_results = process_qloo_entities_with_enrichment(qloo_data, city)
      else
        places_results = perform_generic_search(interests, city)
      end
      
      # Apply fallback if no valid results
      if places_results.empty? || all_missing_coordinates?(places_results)
        Rails.logger.info "=== CREATING LLM FALLBACK ==="
        fallback_place = create_intelligent_fallback(city, interests.first)
        places_results << fallback_place if fallback_place
      end
      
      log_processing_results(places_results)
      places_results
    end

    # Enrich Qloo entities with Google Places data when possible
    def enrich_qloo_with_google_places(qloo_entity, city)
      return nil unless qloo_entity['name'].present?
      
      cache_key = generate_cache_key('google_enrichment', qloo_entity['name'], city)
      
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRES_IN) do
        perform_google_enrichment(qloo_entity, city)
      end
    rescue => e
      Rails.logger.error "Google Places enrichment failed: #{e.message}"
      nil
    end

    # Create Google Places compatible data from Qloo entity
    def create_google_data_from_qloo(qloo_entity, coordinates)
      {
        'name' => qloo_entity['name'],
        'formatted_address' => extract_address_from_qloo(qloo_entity),
        'geometry' => { 'location' => coordinates },
        'place_id' => generate_place_id(qloo_entity),
        'rating' => extract_rating_from_qloo(qloo_entity),
        'types' => extract_types_from_qloo(qloo_entity),
        'photos' => extract_photos_from_qloo(qloo_entity),
        'price_level' => extract_price_level_from_qloo(qloo_entity),
        'opening_hours' => extract_hours_from_qloo(qloo_entity),
        'website' => qloo_entity.dig('properties', 'website'),
        'formatted_phone_number' => qloo_entity.dig('properties', 'phone')
      }.compact
    end

    # Search Google Places as fallback when Qloo data is insufficient
    def search_google_places_fallback(place_name, city)
      query = build_search_query(place_name, city)
      cache_key = generate_cache_key('google_search_with_details', query)
      
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRES_IN) do
        result = perform_google_search(query, city, place_name)
        
        # NUEVO: Enriquecer con detalles si encontramos un lugar
        if result && result['place_id']
          enrich_with_place_details(result)
        else
          result
        end
      end
    rescue => e
      Rails.logger.error "Google Places fallback search failed: #{e.message}"
      nil
    end

    # Calculate distance between two coordinate pairs
    def calculate_distance(lat1, lon1, lat2, lon2)
      return Float::INFINITY unless coordinates_valid?(lat1, lon1, lat2, lon2)
      
      #CulturalCurationService.calculate_distance(lat1, lon1, lat2, lon2)
      rad_per_deg = Math::PI / 180
      rkm = 6371 # Radio de la Tierra en km

      dlat_rad = (lat2 - lat1) * rad_per_deg
      dlon_rad = (lon2 - lon1) * rad_per_deg

      lat1_rad = lat1 * rad_per_deg
      lat2_rad = lat2 * rad_per_deg

      a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
      c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

      rkm * c
    end

    # Validate and clean coordinates
    def validate_coordinates(latitude, longitude)
      return { valid: false, latitude: nil, longitude: nil } unless latitude && longitude
      
      lat = latitude.to_f
      lng = longitude.to_f
      
      valid = lat.between?(-90, 90) && lng.between?(-180, 180) && 
              !lat.zero? && !lng.zero?
      
      {
        valid: valid,
        latitude: valid ? lat : nil,
        longitude: valid ? lng : nil
      }
    end

    # Extract area/neighborhood intelligently using multiple strategies
    def extract_area_with_fallback(google_data, qloo_entity, city, language)
      # Try Google Places address first
      if google_data&.dig('formatted_address')
        area = LlmService.extract_area_from_address(google_data['formatted_address'], city)
        return area if area && area != "Center"
      end
      
      # Try Qloo entity location data
      if qloo_entity
        area = extract_area_from_qloo_properties(qloo_entity, city)
        return area if area && area != "Center"
      end
      
      # Fallback to localized "Center"
      LocalizationService.localize('areas.center', language)
    end

    # Generate comprehensive place metadata
    def generate_place_metadata(google_data, qloo_entity)
      metadata = {}
      
      # Basic information
      metadata[:data_sources] = []
      metadata[:data_sources] << 'google_places' if google_data
      metadata[:data_sources] << 'qloo' if qloo_entity
      
      # Quality indicators
      metadata[:data_quality] = calculate_data_quality(google_data, qloo_entity)
      metadata[:verification_status] = determine_verification_status(google_data, qloo_entity)
      
      # Coordinate source tracking
      if google_data&.dig('geometry', 'location')
        metadata[:coordinate_source] = 'google_places'
        metadata[:coordinate_precision] = 'high'
      elsif qloo_entity&.dig('location')
        metadata[:coordinate_source] = 'qloo'
        metadata[:coordinate_precision] = 'medium'
      else
        metadata[:coordinate_source] = 'fallback'
        metadata[:coordinate_precision] = 'low'
      end
      
      # Last updated
      metadata[:last_enriched] = Time.current.iso8601
      
      metadata
    end

    private

    def has_qloo_entities?(qloo_data)
      qloo_data&.dig('results', 'entities')&.any?
    end

    def all_missing_coordinates?(places_results)
      places_results.all? { |place| place[:google_data]&.dig('geometry', 'location').nil? }
    end

    def process_qloo_entities_with_enrichment(qloo_data, city)
      qloo_entities = qloo_data.dig('results', 'entities').first(3)
      places_results = []
      
      qloo_entities.each_with_index do |entity, index|
        place_result = process_single_qloo_entity(entity, city, index)
        places_results << place_result if place_result
      end
      
      places_results
    end

    def process_single_qloo_entity(entity, city, index)
      place_name = entity['name']
      qloo_location = entity['location']
      
      Rails.logger.info "--- Processing entity #{index + 1}: #{place_name}"
      
      if coordinates_available_in_qloo?(qloo_location)
        process_entity_with_coordinates(entity, city, qloo_location)
      else
        process_entity_without_coordinates(entity, city)
      end
    end

    def coordinates_available_in_qloo?(qloo_location)
      qloo_location && qloo_location['lat'] && qloo_location['lon']
    end

    def process_entity_with_coordinates(entity, city, qloo_location)
      coordinates = normalize_coordinates(qloo_location)
      
      # Try to enrich with Google Places data
      enriched_data = enrich_qloo_with_google_places(entity, city)
      
      if enriched_data && coordinates_match?(enriched_data, coordinates)
        # Use enriched data but keep Qloo coordinates
        enriched_data['geometry']['location'] = coordinates
        google_data = enriched_data
      else
        # Create Google-compatible data from Qloo
        google_data = create_google_data_from_qloo(entity, coordinates)
      end
      
      Rails.logger.info "--- ✅ USING QLOO COORDS: #{entity['name']} - #{coordinates.inspect}"
      
      {
        name: entity['name'],
        google_data: google_data,
        qloo_entity: entity,
        metadata: generate_place_metadata(google_data, entity)
      }
    end

    def process_entity_without_coordinates(entity, city)
      Rails.logger.info "--- ❌ No coordinates in Qloo for: #{entity['name']}, searching Google..."
      
      google_result = search_google_places_fallback(entity['name'], city)
      
      {
        name: entity['name'],
        google_data: google_result,
        qloo_entity: entity,
        metadata: generate_place_metadata(google_result, entity)
      }
    end

    def perform_generic_search(interests, city)
      Rails.logger.info "=== NO QLOO DATA - USING GENERIC SEARCH ==="
      generic_queries = build_fallback_queries(interests, city)
      places_results = []
      
      generic_queries.each_with_index do |query, index|
        Rails.logger.info "--- Generic Query #{index + 1}: #{query}"
        place_result = perform_single_generic_search(query, city)
        places_results << place_result if place_result
      end
      
      places_results
    end

    def perform_single_generic_search(query, city)
      begin
        google_result = RdawnApiService.google_places(query: query)
        
        if google_result[:success] && google_result[:data]&.dig('results')&.any?
          places_data = prepare_places_data_for_matching(google_result[:data]['results'])
          best_place = LlmService.find_best_place_match(places_data, city)
          
          if best_place
            coordinates = best_place.dig('geometry', 'location')
            Rails.logger.info "--- ✅ GENERIC PLACE FOUND: #{best_place['name']} - #{coordinates.inspect}"
            
            return {
              name: best_place['name'],
              google_data: best_place,
              qloo_entity: nil,
              metadata: generate_place_metadata(best_place, nil)
            }
          end
        end
        
        nil
      rescue => e
        Rails.logger.error "--- ❌ ERROR in generic search: #{e.message}"
        nil
      end
    end

    def prepare_places_data_for_matching(results)
      results.map do |place|
        {
          name: place['name'],
          address: place['formatted_address'],
          rating: place['rating'],
          types: place['types']&.join(', ')
        }
      end
    end

    def normalize_coordinates(qloo_location)
      {
        'lat' => qloo_location['lat'].to_f,
        'lng' => qloo_location['lon'].to_f
      }
    end

    def coordinates_match?(enriched_data, qloo_coordinates)
      google_coords = enriched_data&.dig('geometry', 'location')
      return false unless google_coords
      
      distance = self.calculate_distance( # o simplemente calculate_distance
        qloo_coordinates['lat'], qloo_coordinates['lng'],
        google_coords['lat'], google_coords['lng']
      )
 
      distance < COORDINATE_MATCH_THRESHOLD
    end

    def perform_google_enrichment(qloo_entity, city)
      query = "#{qloo_entity['name']} #{city}"
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        results = google_result[:data]['results']
        
        # Find the best match based on name similarity and location
        best_match = find_best_google_match(results, qloo_entity, city)
        
        # NUEVO: Enriquecer con detalles del lugar
        if best_match && best_match['place_id']
          enriched_match = enrich_with_place_details(best_match)
          return enriched_match if enriched_match
        end
        
        return best_match
      end
      
      nil
    end

    def enrich_with_place_details(place_data)
      return place_data unless place_data['place_id']
      
      # Verificar si ya tenemos los datos completos
      return place_data if place_data['formatted_phone_number'] || place_data['website']
      
      Rails.logger.info "Fetching place details for: #{place_data['name']} (#{place_data['place_id']})"
      
      # Hacer llamada a Place Details
      details_result = RdawnApiService.google_place_details(place_id: place_data['place_id'])
      
      if details_result[:success] && details_result[:data]&.dig('result')
        details = details_result[:data]['result']
        
        # Combinar los datos
        place_data.merge!(
          'formatted_phone_number' => details['formatted_phone_number'],
          'international_phone_number' => details['international_phone_number'],
          'website' => details['website'],
          'opening_hours' => details['opening_hours'],
          'price_level' => details['price_level'] || place_data['price_level'],
          'rating' => details['rating'] || place_data['rating'],
          'user_ratings_total' => details['user_ratings_total']
        )
      end
      
      place_data
    rescue => e
      Rails.logger.error "Error fetching place details: #{e.message}"
      place_data
    end

    def find_best_google_match(results, qloo_entity, city)
      qloo_coords = qloo_entity['location']
      entity_name = qloo_entity['name'].downcase
      
      # If we have Qloo coordinates, find closest match
      if qloo_coords && qloo_coords['lat'] && qloo_coords['lon']
        return find_closest_coordinate_match(results, qloo_coords)
      end
      
      # Otherwise, find best name match
      find_best_name_match(results, entity_name)
    end

    def find_closest_coordinate_match(results, qloo_coords)
      results.min_by do |place|
        google_coords = place.dig('geometry', 'location')
        next Float::INFINITY unless google_coords
        
        calculate_distance(
          qloo_coords['lat'], qloo_coords['lon'],
          google_coords['lat'], google_coords['lng']
        )
      end
    end

    def find_best_name_match(results, entity_name)
      results.find { |place| place['name'].downcase.include?(entity_name) } || results.first
    end

    def perform_google_search(query, city, place_name = nil)
      google_result = RdawnApiService.google_places(query: query)
      
      if google_result[:success] && google_result[:data]&.dig('results')&.any?
        places_data = prepare_places_data_for_matching(google_result[:data]['results'])
        LlmService.find_best_place_match(places_data, city, place_name)
      else
        nil
      end
    end

    def build_search_query(place_name, city)
      "#{place_name} #{city}".strip
    end

    def create_intelligent_fallback(city, interest)
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
        qloo_entity: nil,
        metadata: {
          data_sources: ['llm_fallback'],
          data_quality: 'low',
          verification_status: 'unverified',
          coordinate_source: 'llm_generated',
          coordinate_precision: 'low'
        }
      }
    end

    # Data extraction helpers
    def extract_address_from_qloo(qloo_entity)
      qloo_entity.dig('properties', 'address') || 
      "#{qloo_entity['name']}, Location"
    end

    def generate_place_id(qloo_entity)
      qloo_entity['entity_id'] || "qloo_#{SecureRandom.hex(4)}"
    end

    def extract_rating_from_qloo(qloo_entity)
      qloo_entity.dig('properties', 'business_rating')&.to_f || 
      qloo_entity.dig('properties', 'rating')&.to_f || 
      4.0
    end

    def extract_types_from_qloo(qloo_entity)
      tags = qloo_entity['tags'] || []
      types = []
      
      tags.each do |tag|
        tag_name = tag['name']&.downcase
        case tag_name
        when /hotel|hostel/ then types << 'lodging'
        when /restaurant/ then types << 'restaurant'
        when /bar/ then types << 'bar'
        when /museum/ then types << 'museum'
        when /park/ then types << 'park'
        when /shop|store/ then types << 'store'
        end
      end
      
      types << 'point_of_interest' if types.empty?
      types << 'establishment'
      types.uniq
    end

    def extract_photos_from_qloo(qloo_entity)
      images = qloo_entity.dig('properties', 'images') || []
      return nil if images.empty?
      
      images.map do |image|
        {
          'photo_reference' => SecureRandom.hex(10),
          'height' => 400,
          'width' => 400,
          'html_attributions' => ['Qloo'],
          'url' => image.is_a?(Hash) ? image['url'] : image
        }
      end.first(5) # Limit to 5 photos
    end

    def extract_price_level_from_qloo(qloo_entity)
      qloo_entity.dig('properties', 'price_level')&.to_i
    end

    def extract_hours_from_qloo(qloo_entity)
      hours_data = qloo_entity.dig('properties', 'hours')
      return nil unless hours_data
      
      {
        'open_now' => determine_open_status(hours_data),
        'periods' => format_hours_periods(hours_data),
        'weekday_text' => format_weekday_text(hours_data)
      }
    end

    def extract_area_from_qloo_properties(qloo_entity, city)
      area_candidates = [
        qloo_entity.dig('properties', 'neighborhood'),
        qloo_entity.dig('properties', 'district'),
        qloo_entity.dig('properties', 'area'),
        qloo_entity.dig('location', 'neighborhood')
      ].compact.map(&:strip)
      
      area_candidates.find { |area| area.length > 2 && !area.downcase.include?(city.downcase) }
    end

    # Utility methods
    def coordinates_valid?(*coords)
      coords.all? { |coord| coord.present? && coord.respond_to?(:to_f) }
    end

    def generate_cache_key(*parts)
      "places_enrichment:#{parts.join(':')}"
    end

    def calculate_data_quality(google_data, qloo_entity)
      score = 0
      
      # Google data quality indicators
      if google_data
        score += 30 # Base score for Google data
        score += 10 if google_data['rating'].present?
        score += 10 if google_data['formatted_phone_number'].present?
        score += 10 if google_data['website'].present?
        score += 5 if google_data['photos'].present?
      end
      
      # Qloo data quality indicators
      if qloo_entity
        score += 20 # Base score for Qloo data
        score += 10 if qloo_entity.dig('location', 'lat').present?
        score += 5 if qloo_entity.dig('properties', 'description').present?
      end
      
      case score
      when 80..100 then 'high'
      when 50..79 then 'medium'
      when 25..49 then 'low'
      else 'very_low'
      end
    end

    def determine_verification_status(google_data, qloo_entity)
      if google_data && qloo_entity
        'cross_verified'
      elsif google_data
        'google_verified'
      elsif qloo_entity
        'qloo_verified'
      else
        'unverified'
      end
    end

    def determine_open_status(hours_data)
      # Simplified open status determination
      # In a real implementation, this would check current time against hours
      true
    end

    def format_hours_periods(hours_data)
      # Convert Qloo hours format to Google Places format
      # This is a simplified implementation
      []
    end

    def format_weekday_text(hours_data)
      # Convert to human-readable weekday text
      []
    end

    def build_fallback_queries(interests, city)
      CulturalCurationService.send(:build_fallback_queries, interests, city)
    end

    def log_processing_results(places_results)
      Rails.logger.info "=== FINAL PLACES RESULT ==="
      Rails.logger.info "Total places found: #{places_results.size}"
      
      places_results.each_with_index do |result, index|
        coords = result[:google_data]&.dig('geometry', 'location')
        quality = result[:metadata]&.dig(:data_quality) || 'unknown'
        sources = result[:metadata]&.dig(:data_sources)&.join(', ') || 'unknown'
        
        Rails.logger.info "#{index + 1}. #{result[:name]} - Coords: #{coords&.inspect || 'NO COORDINATES'} - Quality: #{quality} - Sources: #{sources}"
      end
    end
  end
end
