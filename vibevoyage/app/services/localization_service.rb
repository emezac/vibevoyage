# app/services/localization_service.rb
class LocalizationService
  SUPPORTED_LANGUAGES = %w[es en fr pt it de].freeze
  DEFAULT_LANGUAGE = 'en'.freeze
  
  # Language configurations with all localized content
  LANGUAGE_CONFIG = {
    'es' => {
      name: 'Spanish',
      direction: 'ltr',
      ui_labels: {
        cultural_resonance: "Resonancia Cultural",
        cultural_dna_from_qloo: "ADN Cultural de Qloo:",
        cultural_vibe_match: "Coincidencia Cultural",
        rating: "puntuación",
        directions: "Direcciones",
        website: "Sitio Web",
        call: "Llamar", 
        open_now: "Abierto ahora",
        closed_now: "Cerrado ahora",
        closed_today: "Cerrado hoy",
        hours: "horas"
      },
      narrative_labels: {
        adventure_title: "Tu Aventura Cultural en",
        original_vibe: "Tu vibe original:",
        destination: "Destino Identificado",
        interests: "Intereses Detectados",
        curation: "Curación Inteligente"
      },
      messages: {
        adventure_ready: "¡Tu aventura cultural está lista!",
        adventure_ready_offline: "¡Tu aventura está lista! (Modo offline)",
        experience_created: "Hemos creado una experiencia cultural curada para ti en",
        based_on_preferences: "basada en tus preferencias."
      },
      areas: {
        center: "Centro",
        historic: "Distrito Histórico", 
        entertainment: "Zona de Entretenimiento"
      },
      locations: {
        cultural_center: "Centro Cultural de",
        traditional_restaurant: "Restaurante Tradicional",
        nocturnal_space: "Espacio Cultural Nocturno"
      },
      time_periods: {
        morning: "Mañana:",
        afternoon: "Tarde:", 
        evening: "Noche:"
      },
      experience_descriptors: {
        discovery: "Descubrimiento Cultural",
        immersion: "Inmersión Auténtica", 
        culmination: "Culminación Perfecta"
      }
    },
    
    'en' => {
      name: 'English',
      direction: 'ltr',
      ui_labels: {
        cultural_resonance: "Cultural Resonance",
        cultural_dna_from_qloo: "Cultural DNA from Qloo:",
        cultural_vibe_match: "Cultural Vibe Match", 
        rating: "rating",
        directions: "Directions",
        website: "Website",
        call: "Call",
        open_now: "Open now",
        closed_now: "Closed now", 
        closed_today: "Closed today",
        hours: "hours"
      },
      narrative_labels: {
        adventure_title: "Your Cultural Adventure in",
        original_vibe: "Your original vibe:",
        destination: "Identified Destination", 
        interests: "Detected Interests",
        curation: "Intelligent Curation"
      },
      messages: {
        adventure_ready: "Your cultural adventure is ready!",
        adventure_ready_offline: "Your adventure is ready! (Offline mode)",
        experience_created: "We've created a curated cultural experience for you in",
        based_on_preferences: "based on your preferences."
      },
      areas: {
        center: "Center",
        historic: "Historic District",
        entertainment: "Entertainment Zone"
      },
      locations: {
        cultural_center: "Cultural Center of",
        traditional_restaurant: "Traditional Restaurant",
        nocturnal_space: "Nocturnal Cultural Space"
      },
      time_periods: {
        morning: "Morning:",
        afternoon: "Afternoon:",
        evening: "Evening:"
      },
      experience_descriptors: {
        discovery: "Cultural Discovery",
        immersion: "Authentic Immersion",
        culmination: "Perfect Culmination"
      }
    },
    
    'fr' => {
      name: 'French',
      direction: 'ltr',
      ui_labels: {
        cultural_resonance: "Résonance Culturelle",
        cultural_dna_from_qloo: "ADN Culturel de Qloo :",
        cultural_vibe_match: "Correspondance Culturelle",
        rating: "note",
        directions: "Itinéraire",
        website: "Site Web", 
        call: "Appeler",
        open_now: "Ouvert maintenant",
        closed_now: "Fermé maintenant",
        closed_today: "Fermé aujourd'hui",
        hours: "heures"
      },
      narrative_labels: {
        adventure_title: "Votre Aventure Culturelle à",
        original_vibe: "Votre vibe original:",
        destination: "Destination Identifiée",
        interests: "Intérêts Détectés",
        curation: "Curation Intelligente"
      },
      messages: {
        adventure_ready: "Votre aventure culturelle est prête!",
        adventure_ready_offline: "Votre aventure est prête! (Mode hors ligne)",
        experience_created: "Nous avons créé une expérience culturelle curatée pour vous à",
        based_on_preferences: "basée sur vos préférences."
      },
      areas: {
        center: "Centre",
        historic: "District Historique",
        entertainment: "Zone de Divertissement"
      },
      locations: {
        cultural_center: "Centre Culturel de",
        traditional_restaurant: "Restaurant Traditionnel",
        nocturnal_space: "Espace Culturel Nocturne"
      },
      time_periods: {
        morning: "Matin:",
        afternoon: "Après-midi:",
        evening: "Soir:"
      },
      experience_descriptors: {
        discovery: "Découverte Culturelle",
        immersion: "Immersion Authentique",
        culmination: "Culmination Parfaite"
      }
    }
  }.freeze

  class << self

    # ===== ENHANCED LANGUAGE DETECTION WITH WHATLANGUAGE =====
    def detect_language(text)
      return DEFAULT_LANGUAGE if text.blank?
      
      begin
        # Primary detection using WhatLanguage
        require 'whatlanguage'
        wl = WhatLanguage.new(:all)
        detected_symbol = wl.language(text.to_s)
        
        if detected_symbol
          # Map WhatLanguage symbols to our supported language codes
          mapped_code = map_whatlanguage_to_supported(detected_symbol)
          
          if supported_language?(mapped_code)
            Rails.logger.info "WhatLanguage detected: #{detected_symbol} -> #{mapped_code}" if defined?(Rails)
            return mapped_code
          end
        end
        
        Rails.logger.info "WhatLanguage detection unsupported (#{detected_symbol}), falling back to pattern detection" if defined?(Rails)
        
        # Fallback to pattern detection if WhatLanguage fails or returns unsupported language
        pattern_detected = detect_by_patterns(text)
        return pattern_detected if pattern_detected && supported_language?(pattern_detected)
        
      rescue => e
        Rails.logger.error "WhatLanguage detection failed: #{e.message}, falling back to pattern detection" if defined?(Rails)
        
        # Fallback to pattern detection if WhatLanguage fails
        pattern_detected = detect_by_patterns(text)
        return pattern_detected if pattern_detected && supported_language?(pattern_detected)
      end
      
      # Ultimate fallback
      DEFAULT_LANGUAGE
    end

    # Enhanced progress messages with Qloo insights
    def get_progress_messages(language)
      case language
      when 'fr'
        {
          analyzing_vibe: "Analysons votre essence culturelle...",
          vibe_discovered: "Vibe découvert: \"%{vibe_summary}\"",
          querying_qloo: "Consultation de l'oracle culturel Qloo...",
          qloo_thinking: "Qloo analyse %{interests_count} intérêts culturels...",
          qloo_discovery: "✨ Découverte! Les fans de \"%{interest}\" aiment aussi: %{discoveries}",
          qloo_connections: "🧠 Qloo a trouvé %{connections_count} connexions culturelles",
          enriching_places: "Enrichissement des lieux avec données détaillées...",
          building_narrative: "Tissage de votre tapisserie narrative...",
          cultural_synthesis: "Synthèse de votre symphonie culturelle...",
          ready: "Votre voyage culturel est prêt!"
        }
      when 'es'
        {
          analyzing_vibe: "Analizando tu esencia cultural...",
          vibe_discovered: "Vibe descubierto: \"%{vibe_summary}\"",
          querying_qloo: "Consultando el oráculo cultural de Qloo...",
          qloo_thinking: "Qloo analiza %{interests_count} intereses culturales...",
          qloo_discovery: "✨ ¡Descubrimiento! A los fans de \"%{interest}\" también les gusta: %{discoveries}",
          qloo_connections: "🧠 Qloo encontró %{connections_count} conexiones culturales",
          enriching_places: "Enriqueciendo lugares con datos detallados...",
          building_narrative: "Tejiendo tu tapiz narrativo...",
          cultural_synthesis: "Sintetizando tu sinfonía cultural...",
          ready: "¡Tu aventura cultural está lista!"
        }
      else # English
        {
          analyzing_vibe: "Analyzing your cultural essence...",
          vibe_discovered: "Vibe discovered: \"%{vibe_summary}\"",
          querying_qloo: "Querying Qloo's cultural oracle...",
          qloo_thinking: "Qloo analyzing %{interests_count} cultural interests...",
          qloo_discovery: "✨ Discovery! Fans of \"%{interest}\" also love: %{discoveries}",
          qloo_connections: "🧠 Qloo found %{connections_count} cultural connections",
          enriching_places: "Enriching places with detailed data...",
          building_narrative: "Weaving your narrative tapestry...",
          cultural_synthesis: "Synthesizing your cultural symphony...",
          ready: "Your cultural adventure is ready!"
        }
      end
    end

    def format_qloo_discovery(interest, related_keywords, language)
      messages = get_progress_messages(language)
      discoveries = related_keywords.first(3).join(', ')
      
      messages[:qloo_discovery] % { 
        interest: interest, 
        discoveries: discoveries 
      }
    end

    def format_qloo_connections(connections_count, language)
      messages = get_progress_messages(language)
      messages[:qloo_connections] % { connections_count: connections_count }
    end

    def format_vibe_discovery(interests, city, language)
      messages = get_progress_messages(language)
      vibe_summary = "#{interests.first(2).join(' + ')} en #{city}"
      
      messages[:vibe_discovered] % { vibe_summary: vibe_summary }
    end

    def get_ui_translations(language)
      normalized_lang = normalize_language(language)
      config = language_config(normalized_lang)
      
      base_translations = config.dig('ui_labels') || {}
      
      # Add time period translations
      time_periods = config.dig('time_periods') || {}
      time_translations = {
        'morning' => time_periods[:morning]&.gsub(':', '') || 'Morning',
        'afternoon' => time_periods[:afternoon]&.gsub(':', '') || 'Afternoon',
        'evening' => time_periods[:evening]&.gsub(':', '') || 'Evening'
      }
      
      base_translations.merge(time_translations)
    end

    def get_ui_label(key, language)
      translations = get_ui_translations(language)
      translations[key.to_s] || key.to_s.humanize
    end

    def experience_title(time_period, descriptor, language)
      time_labels = get_ui_translations(language)
      time = time_labels[time_period.to_s] || time_period.to_s.humanize
      
      config = language_config(language)
      descriptors = config.dig('experience_descriptors') || {}
      desc = descriptors[descriptor] || descriptor.to_s.humanize
      
      "#{time}: #{desc}"
    end

    def supported_language?(lang_code)
      SUPPORTED_LANGUAGES.include?(lang_code.to_s.downcase)
    end

    def normalize_language(lang_code)
      normalized = lang_code.to_s.downcase.strip
      supported_language?(normalized) ? normalized : DEFAULT_LANGUAGE
    end

    def localize(key_path, language, **interpolations)
      return "[Missing: nil]" if key_path.nil?
      
      config = language_config(language)
      value = get_nested_value(config, key_path)
      
      return "[Missing: #{key_path}]" if value.nil?
      
      # Handle interpolations
      if interpolations.any? && value.is_a?(String)
        begin
          value % interpolations
        rescue => e
          Rails.logger.error "Interpolation failed for #{key_path}: #{e.message}" if defined?(Rails)
          value
        end
      else
        value
      end
    end

    def adventure_title(city, language)
      title_template = localize('narrative_labels.adventure_title', language)
      city_name = city.to_s.empty? ? 'Unknown City' : city.to_s
      "#{title_template} #{city_name}"
    end

    def cultural_location(location_type, city, language)
      location_template = localize("locations.#{location_type}", language)
      city_name = city.to_s.empty? ? 'Unknown City' : city.to_s
      "#{location_template} #{city_name}"
    end

    def success_message(offline: false, language:)
      key = offline ? 'messages.adventure_ready_offline' : 'messages.adventure_ready'
      localize(key, language)
    end

    def generate_fallback_experiences(city, interests, language)
      city = city.to_s.empty? ? 'Unknown City' : city.to_s
      interests = Array(interests).compact
      interests_text = interests.any? ? interests.join(', ') : 'cultural experiences'
      
      time_periods = [:morning, :afternoon, :evening]
      descriptors = [:discovery, :immersion, :culmination]
      location_types = [:cultural_center, :traditional_restaurant, :nocturnal_space]
      area_types = [:center, :historic, :entertainment]
      
      experiences = []
      
      3.times do |index|
        experiences << {
          time: ["10:00 AM", "02:00 PM", "07:30 PM"][index],
          title: experience_title(time_periods[index], descriptors[index], language),
          location: cultural_location(location_types[index], city, language),
          description: generate_fallback_description(index, city, language),
          cultural_explanation: generate_fallback_explanation(index, city, interests_text, language),
          duration: ["2 hours", "2.5 hours", "3 hours"][index],
          area: localize("areas.#{area_types[index]}", language),
          vibe_match: [85, 88, 82][index],
          rating: [4.2, 4.4, 4.1][index],
          image: get_experience_image(index),
          qloo_keywords: [],
          why_chosen: generate_fallback_why_chosen(index, city, language)
        }
      end
      
      experiences
    end

    def build_narrative_html(user_vibe, city, interests, experiences_count, language)
      require 'cgi'
      safe_user_vibe = CGI.escapeHTML(user_vibe.to_s)

      user_vibe = user_vibe.to_s.empty? ? 'Cultural exploration' : user_vibe.to_s
      city = city.to_s.empty? ? 'Unknown City' : city.to_s
      interests = Array(interests).compact
      interests_text = interests.any? ? interests.join(', ') : 'cultural experiences'
      
      title = adventure_title(city, language)
      original_vibe_label = localize('narrative_labels.original_vibe', language)
      destination_label = localize('narrative_labels.destination', language) 
      interests_label = localize('narrative_labels.interests', language)
      curation_label = localize('narrative_labels.curation', language)
      
      description = build_curation_description(experiences_count, city, language)
      
      <<~HTML
        <div class="narrative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-8 rounded-2xl">
          <h2 class="text-3xl font-bold mb-6 gradient-text">🌟 #{title}</h2>
          
          <div class="glass-card p-6 mb-6">
            <p class="text-lg text-slate-300 mb-4">
              <strong class="text-white">#{original_vibe_label}</strong> 
              <em>"#{safe_user_vibe}"</em>
            </p>
          </div>
          
          <div class="grid md:grid-cols-2 gap-6 mb-6">
            <div class="glass-card p-6">
              <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
                📍 <span style="color: var(--accent-terracotta);">#{destination_label}</span>
              </h3>
              <p class="text-slate-300">#{city}</p>
            </div>
            
            <div class="glass-card p-6">
              <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
                🎯 <span style="color: var(--accent-sage);">#{interests_label}</span>
              </h3>
              <p class="text-slate-300">#{interests_text}</p>
            </div>
          </div>
          
          <div class="glass-card p-6">
            <h3 class="text-xl font-bold mb-3 flex items-center gap-2">
              ✨ <span style="color: var(--accent-gold);">#{curation_label}</span>
            </h3>
            <p class="text-slate-300">#{description}</p>
          </div>
        </div>
      HTML
    end

    private

    def map_whatlanguage_to_supported(language_symbol)
      case language_symbol.to_s.downcase
      when 'spanish' then 'es'
      when 'english' then 'en'
      when 'french' then 'fr'
      when 'portuguese' then 'pt'
      when 'italian' then 'it'
      when 'german' then 'de'
      else DEFAULT_LANGUAGE
      end
    end

    def detect_by_patterns(text)
      text_lower = text.downcase

      # Detect English patterns first to avoid false French detection
      return 'en' if text_lower.match?(/\b(i'm|drawn|vintage|experimental|meat.forward|steak|houses|saturday)\b/)

      # Enhanced French detection - more specific patterns
      french_patterns = [
        /\bj'ai\b/, /\bc'est\b/, /\bqu'il\b/, /\bd'un\b/, /\bl'art\b/, /\bs'il\b/,
        /\bune?\b/, /\bdu\b/, /\bde la\b/, /\bdes\b/, /\bau\b/, /\baux\b/,
        /\bà\b/, /\bpour\b/, /\bavec\b/, /\bdans\b/, /\bsur\b/, /\bpar\b/,
        /\bvoudrais\b/, /\baimerais\b/, /\benvi[eè]\b/, /\bcontempler\b/,
        /\bjourné[eè]\b/, /\bsoiré[eè]\b/, /\baprès.midi\b/,
        /[àâäéèêëïîôöùûüÿç]/,
        /\bqu'est.ce\b/, /\bcomment\b/, /\bpourquoi\b/, /\boù\b/
      ]
      
      french_score = french_patterns.count { |pattern| text_lower.match?(pattern) }
      french_score += 3 if text_lower.match?(/\bj'ai\b|\bc'est\b|\bqu'est.ce\b/)
      french_score += 2 if text_lower.match?(/\benvie\b|\bcontempler\b/)
      
      return 'fr' if french_score >= 3
      return 'de' if text_lower.match?(/\b(ein|eine|mit|abend|lokalen|spezialitäten|kultureller)\b/)
      return 'it' if text_lower.match?(/\b(serata|mangiare|dove|esperienza)\b/) && 
                    !text_lower.match?(/\b(ciudad|deseo|cerveza|sopa)\b/)

      # Spanish vs Portuguese scoring
      pt_score = text_lower.scan(/\b(uma|são|você|experiência|com)\b/).count
      pt_score += 2 if text_lower.include?('ão')
      pt_score += 1 if text_lower.include?('ç')
      
      es_score = text_lower.scan(/\b(una|qué|ciudad|tarde|deseo|con|cerveza|sopa|experiencia)\b/).count
      es_score += 2 if text_lower.include?('ñ')
      es_score += 1 if text_lower.match?(/\b(en|de|y|la|el)\b/)
      
      return 'pt' if pt_score > es_score
      return 'es' if es_score > pt_score
      return 'pt' if text_lower.include?('uma') && !text_lower.include?('una')
      return 'es' if text_lower.include?('una') && !text_lower.include?('uma')
      return 'es' if text_lower.match?(/\b(deseo|cerveza|sopa)\b/)
      
      nil
    end

    def language_config(language)
      normalized_lang = normalize_language(language)
      LANGUAGE_CONFIG[normalized_lang] || LANGUAGE_CONFIG[DEFAULT_LANGUAGE]
    end

    def get_nested_value(hash, key_path)
      keys = key_path.to_s.split('.')
      current = hash
      
      keys.each do |key|
        if current.is_a?(Hash) && current.key?(key.to_s)
          current = current[key.to_s]
        elsif current.is_a?(Hash) && current.key?(key.to_sym)
          current = current[key.to_sym]
        else
          return nil
        end
      end
      
      current
    end

    def generate_fallback_description(index, city, language)
      descriptions = {
        'es' => [
          "Comienza explorando el corazón cultural de #{city}.",
          "Una pausa gastronómica que conecta con la tradición local.",
          "Cierra tu día en un ambiente que captura la esencia nocturna de #{city}."
        ],
        'en' => [
          "Begin exploring the cultural heart of #{city}.",
          "A gastronomic pause that connects with local tradition.",
          "Close your day in an atmosphere that captures the nocturnal essence of #{city}."
        ],
        'fr' => [
          "Commencez en explorant le cœur culturel de #{city}.",
          "Une pause gastronomique qui se connecte à la tradition locale.",
          "Terminez votre journée dans une atmosphère qui capture l'essence nocturne de #{city}."
        ]
      }
      
      lang_descriptions = descriptions[language] || descriptions[DEFAULT_LANGUAGE]
      lang_descriptions[index]
    end

    def generate_fallback_explanation(index, city, interests, language)
      explanations = {
        'es' => [
          "Este lugar representa la esencia cultural de #{city}, perfectamente alineado con tu búsqueda de #{interests}.",
          "La gastronomía local es una ventana al alma de #{city}, y este lugar encarna esa esencia.",
          "La noche revela otra faceta de #{city}, y este lugar es el epítome de esa transformación cultural."
        ],
        'en' => [
          "This place represents the cultural essence of #{city}, perfectly aligned with your search for #{interests}.",
          "Local gastronomy is a window to the soul of #{city}, and this place embodies that essence.",
          "The night reveals another facet of #{city}, and this place is the epitome of that cultural transformation."
        ],
        'fr' => [
          "Cet endroit représente l'essence culturelle de #{city}, parfaitement aligné avec votre recherche de #{interests}.",
          "La gastronomie locale est une fenêtre sur l'âme de #{city}, et cet endroit incarne cette essence.",
          "La nuit révèle une autre facette de #{city}, et cet endroit est l'épitome de cette transformation culturelle."
        ]
      }
      
      lang_explanations = explanations[language] || explanations[DEFAULT_LANGUAGE]
      lang_explanations[index]
    end

    def generate_fallback_why_chosen(index, city, language)
      reasons = {
        'es' => [
          "Seleccionado por su relevancia cultural en #{city}",
          "Elegido por su autenticidad gastronómica",
          "Perfecto para culminar tu jornada cultural"
        ],
        'en' => [
          "Selected for its cultural relevance in #{city}",
          "Chosen for its gastronomic authenticity", 
          "Perfect to culminate your cultural journey"
        ],
        'fr' => [
          "Sélectionné pour sa pertinence culturelle à #{city}",
          "Choisi pour son authenticité gastronomique",
          "Parfait pour culminer votre parcours culturel"
        ]
      }
      
      lang_reasons = reasons[language] || reasons[DEFAULT_LANGUAGE]
      lang_reasons[index]
    end

    def build_curation_description(experiences_count, city, language)
      count = experiences_count || 3
      
      case language
      when 'es'
        "Usando datos culturales de Qloo API y análisis de IA, hemos diseñado #{count} experiencias que capturan la esencia de #{city} y resuenan con tu búsqueda personal."
      when 'fr'
        "En utilisant les données culturelles de l'API Qloo et l'analyse IA, nous avons conçu #{count} expériences qui capturent l'essence de #{city} et résonnent avec votre recherche personnelle."
      else
        "Using Qloo API cultural data and AI analysis, we've designed #{count} experiences that capture the essence of #{city} and resonate with your personal search."
      end
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
end
