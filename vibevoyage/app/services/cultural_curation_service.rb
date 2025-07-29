# app/services/cultural_curation_service.rb
class CulturalCurationService
  include ApplicationHelper

  class << self
    def curate_experiences_from_enriched_places(enriched_places, parsed_vibe)
      Rails.logger.info "=== CURATING EXPERIENCES FROM ENRICHED PLACES ==="
      Rails.logger.info "Processing #{enriched_places.size} enriched places."

      if enriched_places.empty?
        return LocalizationService.generate_fallback_experiences(
          parsed_vibe[:city],
          parsed_vibe[:interests],
          parsed_vibe[:detected_language]
        )
      end

      enriched_places.map.with_index do |place_data, index|
        create_narrative_experience(place_data, parsed_vibe, index)
      end
    end

    def create_narrative_experience(place_data, parsed_vibe, index)
      language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
      qloo_entity = place_data[:qloo_entity] || {}
      qloo_keywords = qloo_entity.dig('properties', 'keywords') || []

      cultural_explanation = LlmService.generate_cultural_explanation(
        qloo_entity,
        parsed_vibe,
        qloo_keywords,
        index
      )

      vibe_match = calculate_vibe_match(qloo_entity, parsed_vibe, qloo_keywords)

      # Usamos el método de enriquecimiento completo AHORA dentro de este servicio
      enhanced_data = extract_enhanced_place_data(place_data, parsed_vibe)

      experience = {
        time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
        title: LocalizationService.experience_title([:morning, :afternoon, :evening][index], [:discovery, :immersion, :culmination][index], language),
        location: place_data[:name],
        description: qloo_entity.dig('properties', 'summary') || "A unique experience in #{parsed_vibe[:city]}.",
        cultural_explanation: cultural_explanation,
        duration: ["2 hours", "2.5 hours", "3 hours"][index],
        vibe_match: vibe_match,
        rating: place_data.dig(:google_data, 'rating') || qloo_entity.dig('properties', 'business_rating')&.to_f || 4.0,
        image: qloo_entity.dig('properties', 'images')&.first&.dig('url') || get_fallback_image(index),
        qloo_keywords: qloo_keywords,
        qloo_entity_id: qloo_entity['entity_id'],
      }.merge(enhanced_data) # Fusionamos los datos enriquecidos

      experience
    end

    # ✅ VERSIÓN CORREGIDA Y COMPLETA DEL MÉTODO DE EXTRACCIÓN
    def extract_enhanced_place_data(place_result, parsed_vibe)
        google_data = place_result[:google_data]
        qloo_entity = place_result[:qloo_entity]
        metadata = place_result[:metadata] || {}
        language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE

        enhanced_data = {}

        if google_data&.dig('geometry', 'location')
            coords = google_data['geometry']['location']
            enhanced_data[:latitude] = coords['lat']
            enhanced_data[:longitude] = coords['lng']
            urls = generate_enhanced_urls(coords['lat'], coords['lng'], google_data['name'])
            enhanced_data.merge!(urls)
        end

        enhanced_data[:website] = google_data&.dig('website')
        enhanced_data[:phone] = google_data&.dig('formatted_phone_number')
        enhanced_data[:address] = google_data&.dig('formatted_address')
        enhanced_data[:rating] = google_data&.dig('rating')&.to_f
        enhanced_data[:price_level] = google_data&.dig('price_level')&.to_i
        enhanced_data[:hours] = google_data&.dig('opening_hours')

        google_price_level = google_data&.dig('price_level')&.to_i

        # Fallback inteligente: si no hay nivel de precios pero es un lugar de comida, asignamos '$$' por defecto.
        if google_price_level.nil? && google_data&.dig('types')&.intersect?(['restaurant', 'cafe', 'bar', 'food'])
          enhanced_data[:price_level] = 2 # Por defecto $$
        else
          enhanced_data[:price_level] = google_price_level
        end

        if defined?(PlacesEnrichmentService)
          enhanced_data[:area] = PlacesEnrichmentService.extract_area_with_fallback(
            google_data, qloo_entity, parsed_vibe[:city], language
          )
        else
          enhanced_data[:area] = LocalizationService.localize('areas.center', language)
        end

        enhanced_data[:data_quality] = metadata[:data_quality]
        enhanced_data[:data_sources] = metadata[:data_sources]
        enhanced_data[:coordinate_precision] = metadata[:coordinate_precision]

        if google_data&.dig('types')
            raw_categories = google_data['types']
            enhanced_data[:categories] = CategoryTranslationHelper.translate_categories(raw_categories, language) if defined?(CategoryTranslationHelper)
        end

        enhanced_data.compact
    end

    def calculate_vibe_match(qloo_entity, parsed_vibe, qloo_keywords = [])
      base_score = ((qloo_entity['popularity'] || 0.8).to_f * 100).round
      user_interests = parsed_vibe[:interests] || []
      keyword_matches = (user_interests & qloo_keywords).size
      keyword_bonus = keyword_matches * 10
      final_score = [base_score + keyword_bonus, 100].min
      [final_score, 75].max
    end

    def generate_enhanced_urls(latitude, longitude, place_name)
      return {} unless latitude && longitude
      {
        google_maps_url: "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}",
        directions_url: "https://www.google.com/maps/dir/?api=1&destination=#{latitude},#{longitude}",
      }
    end

    private

    def get_fallback_image(index)
      images = [
        "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
        "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
        "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
      ]
      images[index] || images.first
    end
  end
end