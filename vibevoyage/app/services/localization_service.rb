# app/services/localization_service.rb
class LocalizationService
  SUPPORTED_LANGUAGES = %w[es en fr pt it de].freeze
  DEFAULT_LANGUAGE = 'en'.freeze
  
  # Language configurations with all localized content
  LANGUAGE_CONFIG = {
    'es' => {
      name: 'Spanish',
      direction: 'ltr',
      cultural_curator_role: "Eres un curador cultural experto.",
      time_periods: {
        morning: "Mañana:",
        afternoon: "Tarde:", 
        evening: "Noche:"
      },
      experience_descriptors: {
        discovery: "Descubrimiento Cultural",
        immersion: "Inmersión Auténtica", 
        culmination: "Culminación Perfecta"
      },
      narrative_labels: {
        adventure_title: "Tu Aventura Cultural en",
        original_vibe: "Tu vibe original:",
        destination: "Destino Identificado",
        interests: "Intereses Detectados",
        curation: "Curación Inteligente"
      },
      experience_actions: {
        begin: "comenzar",
        continue: "continuar",
        culminate: "culminar"
      },
      locations: {
        cultural_center: "Centro Cultural de",
        traditional_restaurant: "Restaurante Tradicional",
        nocturnal_space: "Espacio Cultural Nocturno"
      },
      areas: {
        center: "Centro",
        historic: "Distrito Histórico", 
        entertainment: "Zona de Entretenimiento"
      },
      messages: {
        adventure_ready: "¡Tu aventura cultural está lista!",
        adventure_ready_offline: "¡Tu aventura está lista! (Modo offline)",
        experience_created: "Hemos creado una experiencia cultural curada para ti en",
        based_on_preferences: "basada en tus preferencias."
      },
      prompts: {
        cultural_explanation: "Explica en un párrafo evocador (máximo 100 palabras) por qué este lugar es perfecto para %{action} su aventura cultural.",
        connect_keywords: "Conecta los keywords de Qloo con la experiencia personal del usuario.",
        tone_instruction: "Usa un tono cálido y poético.",
        response_instruction: "Responde solo con el párrafo explicativo."
      },
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
      }
    },
    
    'en' => {
      name: 'English',
      direction: 'ltr',
      cultural_curator_role: "You are an expert cultural curator.",
      time_periods: {
        morning: "Morning:",
        afternoon: "Afternoon:",
        evening: "Evening:"
      },
      experience_descriptors: {
        discovery: "Cultural Discovery",
        immersion: "Authentic Immersion",
        culmination: "Perfect Culmination"
      },
      narrative_labels: {
        adventure_title: "Your Cultural Adventure in",
        original_vibe: "Your original vibe:",
        destination: "Identified Destination", 
        interests: "Detected Interests",
        curation: "Intelligent Curation"
      },
      experience_actions: {
        begin: "begin",
        continue: "continue",
        culminate: "culminate"
      },
      locations: {
        cultural_center: "Cultural Center of",
        traditional_restaurant: "Traditional Restaurant",
        nocturnal_space: "Nocturnal Cultural Space"
      },
      areas: {
        center: "Center",
        historic: "Historic District",
        entertainment: "Entertainment Zone"
      },
      messages: {
        adventure_ready: "Your cultural adventure is ready!",
        adventure_ready_offline: "Your adventure is ready! (Offline mode)",
        experience_created: "We've created a curated cultural experience for you in",
        based_on_preferences: "based on your preferences."
      },
      prompts: {
        cultural_explanation: "Explain in an evocative paragraph (maximum 100 words) why this place is perfect to %{action} their cultural adventure.",
        connect_keywords: "Connect Qloo keywords with the user's personal experience.",
        tone_instruction: "Use a warm and poetic tone.",
        response_instruction: "Respond only with the explanatory paragraph."
      },
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
      }
    },
    
    'fr' => {
      name: 'French',
      direction: 'ltr',
      cultural_curator_role: "Vous êtes un curateur culturel expert.",
      time_periods: {
        morning: "Matin:",
        afternoon: "Après-midi:",
        evening: "Soir:"
      },
      experience_descriptors: {
        discovery: "Découverte Culturelle",
        immersion: "Immersion Authentique",
        culmination: "Culmination Parfaite"
      },
      narrative_labels: {
        adventure_title: "Votre Aventure Culturelle à",
        original_vibe: "Votre vibe original:",
        destination: "Destination Identifiée",
        interests: "Intérêts Détectés",
        curation: "Curation Intelligente"
      },
      experience_actions: {
        begin: "commencer",
        continue: "continuer", 
        culminate: "culminer"
      },
      locations: {
        cultural_center: "Centre Culturel de",
        traditional_restaurant: "Restaurant Traditionnel",
        nocturnal_space: "Espace Culturel Nocturne"
      },
      areas: {
        center: "Centre",
        historic: "District Historique",
        entertainment: "Zone de Divertissement"
      },
      messages: {
        adventure_ready: "Votre aventure culturelle est prête!",
        adventure_ready_offline: "Votre aventure est prête! (Mode hors ligne)",
        experience_created: "Nous avons créé une expérience culturelle curatée pour vous à",
        based_on_preferences: "basée sur vos préférences."
      },
      prompts: {
        cultural_explanation: "Expliquez dans un paragraphe évocateur (maximum 100 mots) pourquoi cet endroit est parfait pour %{action} leur aventure culturelle.",
        connect_keywords: "Connectez les mots-clés de Qloo avec l'expérience personnelle de l'utilisateur.",
        tone_instruction: "Utilisez un ton chaleureux et poétique.",
        response_instruction: "Répondez seulement avec le paragraphe explicatif."
      },
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
      }
    },
    
    'pt' => {
      name: 'Portuguese',
      direction: 'ltr',
      cultural_curator_role: "Você é um curador cultural especialista.",
      time_periods: {
        morning: "Manhã:",
        afternoon: "Tarde:",
        evening: "Noite:"
      },
      experience_descriptors: {
        discovery: "Descoberta Cultural",
        immersion: "Imersão Autêntica",
        culmination: "Culminação Perfeita"
      },
      narrative_labels: {
        adventure_title: "Sua Aventura Cultural em",
        original_vibe: "Seu vibe original:",
        destination: "Destino Identificado",
        interests: "Interesses Detectados",
        curation: "Curadoria Inteligente"
      },
      experience_actions: {
        begin: "começar",
        continue: "continuar",
        culminate: "culminar"
      },
      locations: {
        cultural_center: "Centro Cultural de",
        traditional_restaurant: "Restaurante Tradicional",
        nocturnal_space: "Espaço Cultural Noturno"
      },
      areas: {
        center: "Centro",
        historic: "Distrito Histórico",
        entertainment: "Zona de Entretenimento"
      },
      messages: {
        adventure_ready: "Sua aventura cultural está pronta!",
        adventure_ready_offline: "Sua aventura está pronta! (Modo offline)",
        experience_created: "Criamos uma experiência cultural curada para você em",
        based_on_preferences: "baseada nas suas preferências."
      },
      prompts: {
        cultural_explanation: "Explique em um parágrafo evocativo (máximo 100 palavras) por que este lugar é perfeito para %{action} sua aventura cultural.",
        connect_keywords: "Conecte as palavras-chave do Qloo com a experiência pessoal do usuário.",
        tone_instruction: "Use um tom caloroso e poético.",
        response_instruction: "Responda apenas com o parágrafo explicativo."
      }
    },
    
    'it' => {
      name: 'Italian',
      direction: 'ltr',
      cultural_curator_role: "Sei un curatore culturale esperto.",
      time_periods: {
        morning: "Mattina:",
        afternoon: "Pomeriggio:",
        evening: "Sera:"
      },
      experience_descriptors: {
        discovery: "Scoperta Culturale",
        immersion: "Immersione Autentica",
        culmination: "Culminazione Perfetta"
      },
      narrative_labels: {
        adventure_title: "La Tua Avventura Culturale a",
        original_vibe: "Il tuo vibe originale:",
        destination: "Destinazione Identificata",
        interests: "Interessi Rilevati",
        curation: "Curazione Intelligente"
      },
      experience_actions: {
        begin: "iniziare",
        continue: "continuare",
        culminate: "culminare"
      },
      locations: {
        cultural_center: "Centro Culturale di",
        traditional_restaurant: "Ristorante Tradizionale",
        nocturnal_space: "Spazio Culturale Notturno"
      },
      areas: {
        center: "Centro",
        historic: "Distretto Storico",
        entertainment: "Zona di Intrattenimento"
      },
      messages: {
        adventure_ready: "La tua avventura culturale è pronta!",
        adventure_ready_offline: "La tua avventura è pronta! (Modalità offline)",
        experience_created: "Abbiamo creato un'esperienza culturale curata per te a",
        based_on_preferences: "basata sulle tue preferenze."
      },
      prompts: {
        cultural_explanation: "Spiega in un paragrafo evocativo (massimo 100 parole) perché questo posto è perfetto per %{action} la loro avventura culturale.",
        connect_keywords: "Collega le parole chiave di Qloo con l'esperienza personale dell'utente.",
        tone_instruction: "Usa un tono caldo e poetico.",
        response_instruction: "Rispondi solo con il paragrafo esplicativo."
      }
    },
    
    'de' => {
      name: 'German',
      direction: 'ltr',
      cultural_curator_role: "Sie sind ein erfahrener Kulturkurator.",
      time_periods: {
        morning: "Morgen:",
        afternoon: "Nachmittag:",
        evening: "Abend:"
      },
      experience_descriptors: {
        discovery: "Kulturelle Entdeckung",
        immersion: "Authentische Immersion",
        culmination: "Perfekte Kulmination"
      },
      narrative_labels: {
        adventure_title: "Ihr Kulturelles Abenteuer in",
        original_vibe: "Ihr ursprüngliches Vibe:",
        destination: "Identifiziertes Ziel",
        interests: "Erkannte Interessen",
        curation: "Intelligente Kuration"
      },
      experience_actions: {
        begin: "zu beginnen",
        continue: "fortzusetzen",
        culminate: "zu vollenden"
      },
      locations: {
        cultural_center: "Kulturzentrum von",
        traditional_restaurant: "Traditionelles Restaurant",
        nocturnal_space: "Nächtlicher Kulturraum"
      },
      areas: {
        center: "Zentrum",
        historic: "Historisches Viertel",
        entertainment: "Unterhaltungszone"
      },
      messages: {
        adventure_ready: "Ihr kulturelles Abenteuer ist bereit!",
        adventure_ready_offline: "Ihr Abenteuer ist bereit! (Offline-Modus)",
        experience_created: "Wir haben eine kuratierte kulturelle Erfahrung für Sie in",
        based_on_preferences: "basierend auf Ihren Präferenzen erstellt."
      },
      prompts: {
        cultural_explanation: "Erklären Sie in einem eindringlichen Absatz (maximal 100 Wörter), warum dieser Ort perfekt ist, um %{action} ihr kulturelles Abenteuer.",
        connect_keywords: "Verbinden Sie Qloo-Schlüsselwörter mit der persönlichen Erfahrung des Benutzers.",
        tone_instruction: "Verwenden Sie einen warmen und poetischen Ton.",
        response_instruction: "Antworten Sie nur mit dem erklärenden Absatz."
      }
    }
  }.freeze

  class << self
    # Language detection and validation
    def detect_language(text)
      return DEFAULT_LANGUAGE if text.blank?
      
      # Simple heuristic detection before LLM call
      detected = detect_by_patterns(text)
      return detected if detected && supported_language?(detected)
      
      # Fall back to LLM detection
      defined?(LLMService) ? LLMService.detect_language(text) : DEFAULT_LANGUAGE
    rescue => e
      Rails.logger.error "Language detection failed: #{e.message}" if defined?(Rails)
      DEFAULT_LANGUAGE
    end

    def get_ui_translations(language)
      normalized_lang = normalize_language(language)
      
      case normalized_lang
      when 'fr'
        {
          'cultural_resonance' => 'Résonance Culturelle',
          'cultural_dna_from_qloo' => 'ADN Culturel de Qloo :',
          'cultural_vibe_match' => 'Correspondance Culturelle',
          'rating' => 'note',
          'directions' => 'Itinéraire',
          'website' => 'Site Web',
          'call' => 'Appeler',
          'open_now' => 'Ouvert maintenant',
          'closed_now' => 'Fermé maintenant',
          'closed_today' => 'Fermé aujourd\'hui',
          'hours' => 'heures',
          'morning' => 'Matin',
          'afternoon' => 'Après-midi',
          'evening' => 'Soir'
        }
      when 'es'
        {
          'cultural_resonance' => 'Resonancia Cultural',
          'cultural_dna_from_qloo' => 'ADN Cultural de Qloo:',
          'cultural_vibe_match' => 'Coincidencia Cultural',
          'rating' => 'puntuación',
          'directions' => 'Direcciones',
          'website' => 'Sitio Web',
          'call' => 'Llamar',
          'open_now' => 'Abierto ahora',
          'closed_now' => 'Cerrado ahora',
          'closed_today' => 'Cerrado hoy',
          'hours' => 'horas',
          'morning' => 'Mañana',
          'afternoon' => 'Tarde',
          'evening' => 'Noche'
        }
      when 'pt'
        {
          'cultural_resonance' => 'Ressonância Cultural',
          'cultural_dna_from_qloo' => 'DNA Cultural do Qloo:',
          'cultural_vibe_match' => 'Correspondência Cultural',
          'rating' => 'avaliação',
          'directions' => 'Direções',
          'website' => 'Site',
          'call' => 'Ligar',
          'open_now' => 'Aberto agora',
          'closed_now' => 'Fechado agora',
          'closed_today' => 'Fechado hoje',
          'hours' => 'horas',
          'morning' => 'Manhã',
          'afternoon' => 'Tarde',
          'evening' => 'Noite'
        }
      when 'it'
        {
          'cultural_resonance' => 'Risonanza Culturale',
          'cultural_dna_from_qloo' => 'DNA Culturale di Qloo:',
          'cultural_vibe_match' => 'Corrispondenza Culturale',
          'rating' => 'valutazione',
          'directions' => 'Indicazioni',
          'website' => 'Sito Web',
          'call' => 'Chiama',
          'open_now' => 'Aperto ora',
          'closed_now' => 'Chiuso ora',
          'closed_today' => 'Chiuso oggi',
          'hours' => 'ore',
          'morning' => 'Mattina',
          'afternoon' => 'Pomeriggio',
          'evening' => 'Sera'
        }
      when 'de'
        {
          'cultural_resonance' => 'Kulturelle Resonanz',
          'cultural_dna_from_qloo' => 'Kulturelle DNA von Qloo:',
          'cultural_vibe_match' => 'Kulturelle Übereinstimmung',
          'rating' => 'Bewertung',
          'directions' => 'Wegbeschreibung',
          'website' => 'Webseite',
          'call' => 'Anrufen',
          'open_now' => 'Jetzt geöffnet',
          'closed_now' => 'Jetzt geschlossen',
          'closed_today' => 'Heute geschlossen',
          'hours' => 'Stunden',
          'morning' => 'Morgen',
          'afternoon' => 'Nachmittag',
          'evening' => 'Abend'
        }
      else # English default
        {
          'cultural_resonance' => 'Cultural Resonance',
          'cultural_dna_from_qloo' => 'Cultural DNA from Qloo:',
          'cultural_vibe_match' => 'Cultural Vibe Match',
          'rating' => 'rating',
          'directions' => 'Directions',
          'website' => 'Website',
          'call' => 'Call',
          'open_now' => 'Open now',
          'closed_now' => 'Closed now',
          'closed_today' => 'Closed today',
          'hours' => 'hours',
          'morning' => 'Morning',
          'afternoon' => 'Afternoon',
          'evening' => 'Evening'
        }
      end
    end

    # Get individual UI label
    def get_ui_label(key, language)
      translations = get_ui_translations(language)
      translations[key.to_s] || key.to_s.humanize
    end

    # Enhanced experience title method (fix if missing)
    def experience_title(time_period, descriptor, language)
      time_labels = get_ui_translations(language)
      time = time_labels[time_period.to_s] || time_period.to_s.humanize
      
      descriptors = case language
      when 'fr'
        {
          'discovery' => 'Découverte Culturelle',
          'immersion' => 'Immersion Authentique',
          'culmination' => 'Culmination Parfaite'
        }
      when 'es'
        {
          'discovery' => 'Descubrimiento Cultural',
          'immersion' => 'Inmersión Auténtica',
          'culmination' => 'Culminación Perfecta'
        }
      when 'pt'
        {
          'discovery' => 'Descoberta Cultural',
          'immersion' => 'Imersão Autêntica',
          'culmination' => 'Culminação Perfeita'
        }
      when 'it'
        {
          'discovery' => 'Scoperta Culturale',
          'immersion' => 'Immersione Autentica',
          'culmination' => 'Culminazione Perfetta'
        }
      when 'de'
        {
          'discovery' => 'Kulturelle Entdeckung',
          'immersion' => 'Authentische Immersion',
          'culmination' => 'Perfekte Kulmination'
        }
      else
        {
          'discovery' => 'Cultural Discovery',
          'immersion' => 'Authentic Immersion',
          'culmination' => 'Perfect Culmination'
        }
      end
      
      desc = descriptors[descriptor.to_s] || descriptor.to_s.humanize
      "#{time}: #{desc}"
    end

    def get_ui_label(key, language)
      translations = get_ui_translations(language)
      translations[key.to_s] || key.to_s.humanize
    end

    def supported_language?(lang_code)
      SUPPORTED_LANGUAGES.include?(lang_code.to_s.downcase)
    end

    def normalize_language(lang_code)
      normalized = lang_code.to_s.downcase.strip
      supported_language?(normalized) ? normalized : DEFAULT_LANGUAGE
    end

    # Content localization methods
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

    def experience_title(time_period, descriptor, language)
      time = localize("time_periods.#{time_period}", language)
      desc = localize("experience_descriptors.#{descriptor}", language)
      "#{time} #{desc}"
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

    # Generate localized fallback experiences
    def generate_fallback_experiences(city, interests, language)
      config = language_config(language)
      
      # Handle nil or empty inputs safely
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

    # Build narrative HTML
    def build_narrative_html(user_vibe, city, interests, experiences_count, language)
      require 'cgi'
      safe_user_vibe = CGI.escapeHTML(user_vibe)

      config = language_config(language)
      
      # Handle nil inputs safely
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
              <em>"#{safe_user_vibe}"/em>
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

    def detect_by_patterns(text)
      text_lower = text.downcase

      # Enhanced French detection - patrones muy específicos del francés
      french_patterns = [
        # Contracciones francesas muy específicas
        /\bj'ai\b/, /\bj'/, /\bc'est\b/, /\bqu'/, /\bd'/, /\bl'/, /\bs'/, /\bm'/, /\bt'/,
        # Artículos y preposiciones francesas
        /\bune?\b/, /\bdu\b/, /\bde la\b/, /\bdes\b/, /\bau\b/, /\baux\b/,
        /\bà\b/, /\bpour\b/, /\bavec\b/, /\bdans\b/, /\bsur\b/, /\bpar\b/, /\bdevant\b/,
        # Verbos franceses característicos
        /\bpasser\b/, /\bcontempler\b/, /\bboire\b/, /\bvoir\b/, /\baller\b/,
        /\bvoudrais\b/, /\baimerais\b/, /\benvi[eè]\b/,
        # Vocabulario francés específico
        /\bjourné[eè]\b/, /\bsoiré[eè]\b/, /\bmatin\b/, /\baprès.midi\b/,
        /\bchampagne\b/, /\bseine\b/, /\btour.eiffel\b/, /\bparis\b/,
        # Acentos franceses
        /[àâäéèêëïîôöùûüÿç]/,
        # Terminaciones de verbos franceses
        /er\b/, /ir\b/, /re\b/, /é\b/, /és\b/, /ée\b/, /ées\b/,
        # Palabras interrogativas francesas
        /\bqu'est.ce\b/, /\bcomment\b/, /\bpourquoi\b/, /\boù\b/, /\bquand\b/, /\bque\b/, /\bqui\b/
      ]
      
      # Contar coincidencias francesas
      french_score = french_patterns.count { |pattern| text_lower.match?(pattern) }
      
      # Bonificaciones por indicadores muy fuertes del francés
      french_score += 3 if text_lower.match?(/\bj'ai\b|\bc'est\b|\bqu'est.ce\b/)
      french_score += 2 if text_lower.match?(/\benvie\b|\bcontempler\b|\bchampagne\b/)
      french_score += 2 if text_lower.match?(/\bseine\b|\btour.eiffel\b/)
      french_score += 2 if text_lower.match?(/\bpasser.*journé[eè]\b/)
      
      Rails.logger.info "=== ENHANCED LANGUAGE DETECTION ===" if defined?(Rails)
      Rails.logger.info "Text: #{text[0..100]}" if defined?(Rails)
      Rails.logger.info "French score: #{french_score}" if defined?(Rails)
      
      # Detección fuerte de francés - umbral más bajo para captarlo mejor
      return 'fr' if french_score >= 2
      
      # German - patrones muy distintivos
      return 'de' if text_lower.match?(/\b(ein|eine|mit|abend|lokalen|spezialitäten|kultureller)\b/)
      
      # Italian - usar palabras más específicas solo del italiano
      return 'it' if text_lower.match?(/\b(serata|mangiare|dove|culturale|esperienza)\b/) && 
                    !text_lower.match?(/\b(ciudad|deseo|cerveza|sopa|experiencia)\b/)

      # Spanish vs Portuguese scoring - más comprensivo
      pt_score = 0
      es_score = 0
      
      # Indicadores portugueses
      pt_score += text_lower.scan(/\b(uma|são|você|experiência|paulo|com)\b/).count
      pt_score += 2 if text_lower.include?('ão') # Indicador fuerte del portugués
      pt_score += 1 if text_lower.include?('ç') # ç del portugués
      
      # Indicadores españoles  
      es_score += text_lower.scan(/\b(una|qué|ciudad|tarde|hermosa|contemplativa|deseo|con|cerveza|sopa|experiencia)\b/).count
      es_score += 2 if text_lower.include?('ñ') # Indicador fuerte del español
      es_score += 1 if text_lower.match?(/\b(en|de|y|la|el)\b/) # Palabras comunes del español
      
      # Patrones específicos adicionales del español
      es_score += 1 if text_lower.match?(/\b(merida|yucatan|lima|local)\b/) # Palabras contextuales del input del usuario
      
      if pt_score > es_score
        return 'pt'
      elsif es_score > pt_score
        return 'es'
      end

      # Lógica mejorada de desempate
      return 'pt' if text_lower.include?('uma') && !text_lower.include?('una')
      return 'es' if text_lower.include?('una') && !text_lower.include?('uma')
      return 'es' if text_lower.match?(/\b(deseo|cerveza|sopa)\b/) # Indicadores fuertes del español
      
      # Por defecto devuelve nil para permitir que LLM haga la detección
      nil
    end

    def generate_fallback_description(index, city, language)
      city_name = city.to_s.empty? ? 'the city' : city.to_s
      
      descriptions = {
        'es' => [
          "Comienza explorando el corazón cultural de #{city_name}.",
          "Una pausa gastronómica que conecta con la tradición local.",
          "Cierra tu día en un ambiente que captura la esencia nocturna de #{city_name}."
        ],
        'en' => [
          "Begin exploring the cultural heart of #{city_name}.",
          "A gastronomic pause that connects with local tradition.",
          "Close your day in an atmosphere that captures the nocturnal essence of #{city_name}."
        ],
        'fr' => [
          "Commencez en explorant le cœur culturel de #{city_name}.",
          "Une pause gastronomique qui se connecte à la tradition locale.",
          "Terminez votre journée dans une atmosphère qui capture l'essence nocturne de #{city_name}."
        ],
        'pt' => [
          "Comece explorando o coração cultural de #{city_name}.",
          "Uma pausa gastronômica que conecta com a tradição local.",
          "Termine seu dia em um ambiente que captura a essência noturna de #{city_name}."
        ],
        'it' => [
          "Inizia esplorando il cuore culturale di #{city_name}.",
          "Una pausa gastronomica che si collega alla tradizione locale.",
          "Chiudi la tua giornata in un'atmosfera che cattura l'essenza notturna di #{city_name}."
        ],
        'de' => [
          "Beginnen Sie mit der Erkundung des kulturellen Herzens von #{city_name}.",
          "Eine gastronomische Pause, die sich mit der lokalen Tradition verbindet.",
          "Beenden Sie Ihren Tag in einer Atmosphäre, die die nächtliche Essenz von #{city_name} einfängt."
        ]
      }
      
      lang_descriptions = descriptions[language] || descriptions[DEFAULT_LANGUAGE]
      lang_descriptions[index]
    end

    def generate_fallback_explanation(index, city, interests, language)
      city_name = city.to_s.empty? ? 'this destination' : city.to_s
      interests_text = interests.to_s.empty? ? 'cultural experiences' : interests.to_s
      
      explanations = {
        'es' => [
          "Este lugar representa la esencia cultural de #{city_name}, perfectamente alineado con tu búsqueda de #{interests_text}.",
          "La gastronomía local es una ventana al alma de #{city_name}, y este lugar encarna esa esencia.",
          "La noche revela otra faceta de #{city_name}, y este lugar es el epítome de esa transformación cultural."
        ],
        'en' => [
          "This place represents the cultural essence of #{city_name}, perfectly aligned with your search for #{interests_text}.",
          "Local gastronomy is a window to the soul of #{city_name}, and this place embodies that essence.",
          "The night reveals another facet of #{city_name}, and this place is the epitome of that cultural transformation."
        ],
        'fr' => [
          "Cet endroit représente l'essence culturelle de #{city_name}, parfaitement aligné avec votre recherche de #{interests_text}.",
          "La gastronomie locale est une fenêtre sur l'âme de #{city_name}, et cet endroit incarne cette essence.",
          "La nuit révèle une autre facette de #{city_name}, et cet endroit est l'épitome de cette transformation culturelle."
        ],
        'pt' => [
          "Este lugar representa a essência cultural de #{city_name}, perfeitamente alinhado com sua busca por #{interests_text}.",
          "A gastronomia local é uma janela para a alma de #{city_name}, e este lugar incorpora essa essência.",
          "A noite revela outra faceta de #{city_name}, e este lugar é o epítome dessa transformação cultural."
        ],
        'it' => [
          "Questo posto rappresenta l'essenza culturale di #{city_name}, perfettamente allineato con la tua ricerca di #{interests_text}.",
          "La gastronomia locale è una finestra sull'anima di #{city_name}, e questo posto incarna quell'essenza.",
          "La notte rivela un'altra sfaccettatura di #{city_name}, e questo posto è l'epitome di quella trasformazione culturale."
        ],
        'de' => [
          "Dieser Ort repräsentiert die kulturelle Essenz von #{city_name}, perfekt abgestimmt auf Ihre Suche nach #{interests_text}.",
          "Die lokale Gastronomie ist ein Fenster zur Seele von #{city_name}, und dieser Ort verkörpert diese Essenz.",
          "Die Nacht offenbart eine andere Facette von #{city_name}, und dieser Ort ist der Inbegriff dieser kulturellen Transformation."
        ]
      }
      
      lang_explanations = explanations[language] || explanations[DEFAULT_LANGUAGE]
      lang_explanations[index]
    end

    def generate_fallback_why_chosen(index, city, language)
      city_name = city.to_s.empty? ? 'this destination' : city.to_s
      
      reasons = {
        'es' => [
          "Seleccionado por su relevancia cultural en #{city_name}",
          "Elegido por su autenticidad gastronómica",
          "Perfecto para culminar tu jornada cultural"
        ],
        'en' => [
          "Selected for its cultural relevance in #{city_name}",
          "Chosen for its gastronomic authenticity", 
          "Perfect to culminate your cultural journey"
        ],
        'fr' => [
          "Sélectionné pour sa pertinence culturelle à #{city_name}",
          "Choisi pour son authenticité gastronomique",
          "Parfait pour culminer votre parcours culturel"
        ],
        'pt' => [
          "Selecionado por sua relevância cultural em #{city_name}",
          "Escolhido por sua autenticidade gastronômica",
          "Perfeito para culminar sua jornada cultural"
        ],
        'it' => [
          "Selezionato per la sua rilevanza culturale a #{city_name}",
          "Scelto per la sua autenticità gastronomica",
          "Perfetto per culminare il tuo percorso culturale"
        ],
        'de' => [
          "Ausgewählt für seine kulturelle Relevanz in #{city_name}",
          "Gewählt für seine gastronomische Authentizität",
          "Perfekt, um Ihre kulturelle Reise zu vollenden"
        ]
      }
      
      lang_reasons = reasons[language] || reasons[DEFAULT_LANGUAGE]
      lang_reasons[index]
    end

    def build_curation_description(experiences_count, city, language)
      city_name = city.to_s.empty? ? 'your destination' : city.to_s
      count = experiences_count || 3
      
      case language
      when 'es'
        "Usando datos culturales de Qloo API y análisis de IA, hemos diseñado #{count} experiencias que capturan la esencia de #{city_name} y resuenan con tu búsqueda personal."
      when 'fr'
        "En utilisant les données culturelles de l'API Qloo et l'analyse IA, nous avons conçu #{count} expériences qui capturent l'essence de #{city_name} et résonnent avec votre recherche personnelle."
      when 'pt'
        "Usando dados culturais da API Qloo e análise de IA, projetamos #{count} experiências que capturam a essência de #{city_name} e ressoam com sua busca pessoal."
      when 'it'
        "Utilizzando i dati culturali dell'API Qloo e l'analisi AI, abbiamo progettato #{count} esperienze che catturano l'essenza di #{city_name} e risuonano con la tua ricerca personale."
      when 'de'
        "Mit kulturellen Daten aus der Qloo-API und KI-Analyse haben wir #{count} Erfahrungen entworfen, die die Essenz von #{city_name} erfassen und mit Ihrer persönlichen Suche in Resonanz stehen."
      else
        "Using Qloo API cultural data and AI analysis, we've designed #{count} experiences that capture the essence of #{city_name} and resonate with your personal search."
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