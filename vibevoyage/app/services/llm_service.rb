# app/services/llm_service.rb
class LlmService
  DEFAULT_TEMPERATURE = 0.7
  MAX_TOKENS = 1000
  
  class << self
    # Language detection with caching
    def detect_language(text)
      return LocalizationService::DEFAULT_LANGUAGE if text.blank?
      
      cache_key = "lang_detect:#{Digest::MD5.hexdigest(text)}"
      
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        prompt = build_language_detection_prompt(text)
        response = execute_llm_task(prompt, temperature: 0.1, max_tokens: 10)
        
        detected = response.strip.downcase
        LocalizationService.supported_language?(detected) ? detected : LocalizationService::DEFAULT_LANGUAGE
      end
    rescue => e
      Rails.logger.error "Language detection failed: #{e.message}"
      LocalizationService::DEFAULT_LANGUAGE
    end

      # Simple test method
      def test_cultural_explanation
        Rails.logger.info "=== TESTING CULTURAL EXPLANATION ==="
        
        # Mock data for testing
        test_entity = {
          'name' => 'Test Cultural Center',
          'properties' => {
            'description' => 'A wonderful place for cultural experiences'
          }
        }
        
        test_parsed_vibe = {
          city: 'Paris',
          interests: ['art', 'culture'],
          detected_language: 'fr'
        }
        
        test_keywords = ['art', 'culture', 'museum']
        
        begin
          result = generate_cultural_explanation(test_entity, test_parsed_vibe, test_keywords, 0)
          Rails.logger.info "✅ Test successful: #{result[0..100]}..."
          return result
        rescue => e
          Rails.logger.error "❌ Test failed: #{e.message}"
          return nil
        end
      end

        def diagnose_system
      Rails.logger.info "=== LLM SYSTEM DIAGNOSTIC ==="
      
      # Check 1: Rdawn availability
      rdawn_available = defined?(Rdawn)
      Rails.logger.info "✅ Rdawn available: #{rdawn_available}"
      
      # Check 2: API Key
      api_key = ENV['OPENAI_API_KEY']
      api_key_present = api_key.present?
      Rails.logger.info "✅ OpenAI API key present: #{api_key_present}"
      
      if api_key_present
        Rails.logger.info "   API key preview: #{api_key[0..7]}..."
      else
        Rails.logger.error "❌ Set ENV['OPENAI_API_KEY'] in your environment"
      end
      
      # Check 3: Dependencies
      required_dependencies = %w[SecureRandom JSON]
      required_dependencies.each do |dep|
        begin
          Object.const_get(dep)
          Rails.logger.info "✅ #{dep} available"
        rescue NameError
          Rails.logger.error "❌ #{dep} not available"
        end
      end
      
      # Check 4: Test simple LLM call
      if rdawn_available && api_key_present
        Rails.logger.info "--- Testing simple LLM call..."
        begin
          test_response = execute_llm_task(
            "Say 'Hello' in one word only.",
            temperature: 0.1,
            max_tokens: 5
          )
          Rails.logger.info "✅ LLM test successful: #{test_response}"
        rescue => e
          Rails.logger.error "❌ LLM test failed: #{e.message}"
        end
      else
        Rails.logger.warn "⚠️  Skipping LLM test due to missing dependencies"
      end
      
      # Summary
      all_good = rdawn_available && api_key_present
      Rails.logger.info "=== DIAGNOSTIC SUMMARY ==="
      Rails.logger.info "System ready for LLM: #{all_good}"
      
      unless all_good
        Rails.logger.warn "🔧 REQUIRED ACTIONS:"
        Rails.logger.warn "   1. Install Rdawn gem" unless rdawn_available
        Rails.logger.warn "   2. Set OPENAI_API_KEY environment variable" unless api_key_present
      end
      
      all_good
    end

    # Parse user vibe with improved prompting
    def parse_vibe(user_vibe)
      prompt = build_vibe_parsing_prompt(user_vibe)
      
      response = execute_llm_task(prompt, temperature: 0.3)
      parsed_data = JSON.parse(clean_json_response(response))
      
      # Normalize keys to lowercase
      normalized_data = {}
      parsed_data.each do |key, value|
        normalized_data[key.downcase] = value
      end
      
      # Add detected language
      normalized_data['detected_language'] = detect_language(user_vibe)
      normalized_data.deep_symbolize_keys
      
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse vibe: #{e.message}"
      raise "Invalid LLM response format"
    end

    def generate_cultural_explanation(entity, parsed_vibe, qloo_keywords, experience_index)
      language = parsed_vibe[:detected_language] || LocalizationService::DEFAULT_LANGUAGE
      
      Rails.logger.info "=== GENERATING CULTURAL EXPLANATION ==="
      Rails.logger.info "Entity: #{entity['name']}"
      Rails.logger.info "Language: #{language}"
      Rails.logger.info "Keywords: #{qloo_keywords.inspect}"
      Rails.logger.info "Experience index: #{experience_index}"
      
      begin
        # Step 1: Build prompt
        Rails.logger.info "--- Building prompt..."
        prompt = build_cultural_explanation_prompt(
          entity: entity,
          parsed_vibe: parsed_vibe,
          qloo_keywords: qloo_keywords,
          experience_index: experience_index,
          language: language
        )
        
        Rails.logger.info "--- Prompt built successfully (#{prompt.length} chars)"
        Rails.logger.info "--- First 200 chars: #{prompt[0..200]}"
        
        # Step 2: Execute LLM task
        Rails.logger.info "--- Executing LLM task..."
        response = execute_llm_task(prompt, temperature: 0.8, max_tokens: 150)
        
        Rails.logger.info "--- LLM response received (#{response&.length || 0} chars)"
        Rails.logger.info "--- Raw response: #{response&.[](0..200)}"
        
        # Step 3: Clean response
        cleaned_response = clean_text_response(response)
        Rails.logger.info "--- Cleaned response: #{cleaned_response[0..100]}"
        
        Rails.logger.info "✅ Cultural explanation generated successfully"
        return cleaned_response
        
      rescue => e
        Rails.logger.error "❌ Cultural explanation generation failed: #{e.message}"
        Rails.logger.error "❌ Backtrace: #{e.backtrace.first(5).join("\n")}"
        Rails.logger.error "❌ Using fallback explanation"
        
        fallback = generate_fallback_explanation(entity, parsed_vibe, language)
        Rails.logger.info "--- Fallback explanation: #{fallback}"
        return fallback
      end
    end

    # Find best matching place using LLM
    def find_best_place_match(places_data, target_city, place_name = nil)
      # Handle edge cases first
      return nil if places_data.nil? || places_data.empty?
      return places_data.first if places_data.size == 1
      
      begin
        prompt = build_place_matching_prompt(places_data, target_city, place_name)
        response = execute_llm_task(prompt, temperature: 0.1, max_tokens: 5)
        selected_index = response.strip.to_i
        
        if selected_index >= 0 && selected_index < places_data.size
          places_data[selected_index]
        else
          Rails.logger.warn "Invalid place selection index: #{selected_index}, defaulting to first place" if defined?(Rails)
          places_data.first
        end
      rescue => e
        Rails.logger.error "Place matching failed: #{e.message}, defaulting to first place" if defined?(Rails)
        places_data.first
      end
    end

    # Extract area from address
    def extract_area_from_address(address, city)
      prompt = build_area_extraction_prompt(address, city)
      
      response = execute_llm_task(prompt, temperature: 0.3, max_tokens: 20)
      area = clean_text_response(response)
      
      # Validate and clean area
      area = area.split(',').first&.strip || "Center"
      area.length > 2 ? area : "Center"
      
    rescue => e
      Rails.logger.error "Area extraction failed: #{e.message}"
      "Center"
    end

    # Generate fallback coordinates for a city
    def generate_fallback_coordinates(city, interest = nil)
      prompt = build_coordinates_prompt(city, interest)
      
      response = execute_llm_task(prompt, temperature: 0.1)
      coords_data = JSON.parse(clean_json_response(response))
      
      {
        latitude: coords_data['latitude'].to_f,
        longitude: coords_data['longitude'].to_f,
        place_name: coords_data['place_name'] || "Cultural Center of #{city}"
      }
      
    rescue => e
      Rails.logger.error "Coordinate generation failed: #{e.message}"
      # Emergency fallback
      {
        latitude: 0.0,
        longitude: 0.0,
        place_name: "Center of #{city}"
      }
    end

def execute_llm_task(prompt, temperature: DEFAULT_TEMPERATURE, max_tokens: MAX_TOKENS, retries: 2)
  attempt = 0
  
  Rails.logger.info "=== EXECUTING LLM TASK ==="
  Rails.logger.info "Temperature: #{temperature}, Max tokens: #{max_tokens}, Retries: #{retries}"
  
  begin
    attempt += 1
    Rails.logger.info "--- Attempt #{attempt}/#{retries + 1}"
    
    # Check if Rdawn is available
    unless defined?(Rdawn)
      Rails.logger.error "❌ Rdawn not available!"
      Rails.logger.warn "🔄 Using mock response for development"
      return generate_mock_response(prompt)
    end
    
    Rails.logger.info "✅ Rdawn available"
    
    # Check API key
    api_key = ENV['OPENAI_API_KEY']
    unless api_key.present?
      Rails.logger.error "❌ OpenAI API key not found in ENV['OPENAI_API_KEY']"
      raise "OpenAI API key not configured"
    end
    
    Rails.logger.info "✅ API key present (#{api_key[0..7]}...)"
    
    # Create task
    Rails.logger.info "--- Creating Rdawn task..."
    task = Rdawn::Task.new(
      task_id: "llm_task_#{SecureRandom.hex(4)}",
      name: "LLM Task",
      is_llm_task: true,
      input_data: { 
        prompt: prompt,
        temperature: temperature,
        max_tokens: max_tokens
      }
    )
    Rails.logger.info "✅ Task created: #{task.task_id}"
    
    # Create workflow
    Rails.logger.info "--- Creating workflow..."
    workflow = Rdawn::Workflow.new(workflow_id: "llm_workflow", name: "LLM Workflow")
    workflow.add_task(task)
    Rails.logger.info "✅ Workflow created"
    
    # Create LLM interface
    Rails.logger.info "--- Creating LLM interface..."
    llm_interface = Rdawn::LLMInterface.new(api_key: api_key)
    Rails.logger.info "✅ LLM interface created"
    
    # Create agent
    Rails.logger.info "--- Creating agent..."
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
    Rails.logger.info "✅ Agent created"
    
    # Run agent
    Rails.logger.info "--- Running agent (this calls the LLM API)..."
    result = agent.run
    Rails.logger.info "✅ Agent completed successfully"
    
    # Extract response
    llm_response = result.tasks.values.first.output_data[:llm_response]
    Rails.logger.info "✅ LLM response extracted (#{llm_response&.length || 0} chars)"
    
    if llm_response.blank?
      Rails.logger.error "❌ LLM response is blank!"
      raise "Empty LLM response"
    end
    
    Rails.logger.info "✅ LLM task completed successfully"
    return llm_response
    
  rescue => e
    Rails.logger.error "❌ LLM task failed on attempt #{attempt}: #{e.message}"
    Rails.logger.error "❌ Error class: #{e.class}"
    Rails.logger.error "❌ Backtrace: #{e.backtrace.first(3).join("\n")}"
    
    if attempt < retries
      backoff_time = 0.5 * attempt
      Rails.logger.warn "🔄 Retrying in #{backoff_time} seconds..."
      sleep(backoff_time)
      retry
    else
      Rails.logger.error "❌ LLM task failed after #{retries} attempts"
      raise e
    end
  end
end

def generate_mock_response(prompt)
  Rails.logger.info "=== GENERATING MOCK RESPONSE ==="
  Rails.logger.info "Prompt type detected from content..."
  
  # Language detection mock
  if prompt.include?("Detect the language")
    mock_response = "fr"
    Rails.logger.info "Mock response (language detection): #{mock_response}"
    return mock_response
  end
  
  # Vibe parsing mock
  if prompt.include?("Analyze this cultural preference")
    mock_response = '{"city": "Paris", "interests": ["museum", "art", "culture"], "preferences": ["authentic", "cultural"]}'
    Rails.logger.info "Mock response (vibe parsing): #{mock_response}"
    return mock_response
  end
  
  # Place selection mock
  if prompt.include?("Select the best place")
    mock_response = "0"
    Rails.logger.info "Mock response (place selection): #{mock_response}"
    return mock_response
  end
  
  # Area extraction mock
  if prompt.include?("Extract the neighborhood")
    mock_response = "Montmartre"
    Rails.logger.info "Mock response (area extraction): #{mock_response}"
    return mock_response
  end
  
  # Coordinates mock
  if prompt.include?("coordinates")
    mock_response = '{"latitude": 48.8566, "longitude": 2.3522, "place_name": "Centre Culturel de Paris"}'
    Rails.logger.info "Mock response (coordinates): #{mock_response}"
    return mock_response
  end
  
  # *** CULTURAL EXPLANATION MOCK - MÁS INTELIGENTE ***
  if prompt.include?("cultural") || prompt.include?("culturel") || prompt.include?("aventura")
    # Detect language from prompt
    if prompt.include?("français") || prompt.include?("culturel") || prompt.include?("Vous êtes")
      mock_response = "Ce lieu incarne parfaitement l'esprit culturel authentique de Paris, offrant une expérience immersive qui résonne avec votre quête de découverte artistique et gastronomique."
    elsif prompt.include?("español") || prompt.include?("cultural") || prompt.include?("Eres un")
      mock_response = "Este lugar encarna perfectamente el espíritu cultural auténtico de la ciudad, ofreciendo una experiencia inmersiva que resuena con tu búsqueda de descubrimiento artístico."
    else
      mock_response = "This place perfectly embodies the authentic cultural spirit of the city, offering an immersive experience that resonates with your quest for artistic discovery."
    end
    
    Rails.logger.info "Mock response (cultural explanation): #{mock_response}"
    return mock_response
  end
  
  # Default mock
  mock_response = "This is a mock response for development. The actual LLM would provide a meaningful cultural explanation here."
  Rails.logger.info "Mock response (default): #{mock_response}"
  return mock_response
end

    # Prompt builders
    def build_language_detection_prompt(text)
      <<~PROMPT
        Detect the language of this text and respond with only the language code.
        
        Possible languages:
        - "es" for Spanish
        - "en" for English  
        - "fr" for French
        - "pt" for Portuguese
        - "it" for Italian
        - "de" for German
        
        Text: "#{text}"
        
        Respond with only the 2-letter language code:
      PROMPT
    end

    def build_vibe_parsing_prompt(user_vibe)
      <<~PROMPT
        Analyze this cultural preference text and extract structured data for a recommendation system.

        Extract:
        1. CITY: Any specific city, region, or country mentioned
        2. INTERESTS: Specific venue types, activities, or cultural elements (restaurant, bar, museum, art, music, etc.)
        3. PREFERENCES: General themes or moods (culture, luxury, authentic, nightlife, gastronomy, etc.)

        Rules:
        - Be specific with interests (prefer "wine bar" over "drinking")
        - Include cultural keywords that appear in the text
        - If no city is mentioned, infer from context or use "Mexico City" as default
        - Return ONLY valid JSON

        Text: '#{user_vibe}'

        JSON Response:
      PROMPT
    end

def build_cultural_explanation_prompt(entity:, parsed_vibe:, qloo_keywords:, experience_index:, language:)
  # Simplificar dramáticamente - solo lo esencial
  begin
    # Datos básicos con fallbacks seguros
    entity_name = entity['name'] || 'Cultural Place'
    city = parsed_vibe[:city] || 'the city'
    interests = parsed_vibe[:interests] || []
    interests_text = interests.any? ? interests.join(', ') : 'cultural experiences'
    keywords_text = qloo_keywords.any? ? qloo_keywords.join(', ') : 'cultural experiences'
    
    # Descripción del lugar
    description = entity.dig('properties', 'description') || 
                 entity.dig('properties', 'summary') || 
                 'A cultural venue'
    
    # Mapeo simple de acciones por idioma
    action_map = {
      'fr' => ['commencer', 'continuer', 'culminer'],
      'es' => ['comenzar', 'continuar', 'culminar'],
      'en' => ['begin', 'continue', 'culminate']
    }
    
    actions = action_map[language] || action_map['en']
    action = actions[experience_index] || actions[0]
    
    # Prompts por idioma - MUCHO MÁS SIMPLES
    case language
    when 'fr'
      <<~PROMPT
        Vous êtes un expert en curation culturelle. Expliquez en un paragraphe évocateur (maximum 100 mots) pourquoi #{entity_name} à #{city} est parfait pour #{action} une aventure culturelle.

        Contexte:
        - L'utilisateur recherche: #{interests_text}
        - Lieu: #{entity_name}
        - Description: #{description}
        - Mots-clés culturels: #{keywords_text}

        Connectez les éléments Qloo avec l'expérience personnelle. Utilisez un ton chaleureux et poétique.

        Répondez uniquement avec le paragraphe explicatif:
      PROMPT
    when 'es'
      <<~PROMPT
        Eres un experto curador cultural. Explica en un párrafo evocador (máximo 100 palabras) por qué #{entity_name} en #{city} es perfecto para #{action} una aventura cultural.

        Contexto:
        - El usuario busca: #{interests_text}
        - Lugar: #{entity_name}
        - Descripción: #{description}
        - Keywords culturales: #{keywords_text}

        Conecta los elementos de Qloo con la experiencia personal. Usa un tono cálido y poético.

        Responde solo con el párrafo explicativo:
      PROMPT
    else # English default
      <<~PROMPT
        You are an expert cultural curator. Explain in an evocative paragraph (maximum 100 words) why #{entity_name} in #{city} is perfect to #{action} a cultural adventure.

        Context:
        - User seeks: #{interests_text}
        - Place: #{entity_name}
        - Description: #{description}
        - Cultural keywords: #{keywords_text}

        Connect Qloo elements with personal experience. Use a warm and poetic tone.

        Respond only with the explanatory paragraph:
      PROMPT
    end
    
  rescue => e
    Rails.logger.error "Error building cultural explanation prompt: #{e.message}"
    # Prompt super básico como último recurso
    "Explain why #{entity['name'] || 'this place'} is perfect for a cultural experience in #{parsed_vibe[:city] || 'the city'}. Use a warm tone. Maximum 100 words."
  end
end

    def build_place_matching_prompt(places_data, target_city, place_name)
      options_text = places_data.map.with_index do |place, index|
        "#{index}. #{place[:name]} - #{place[:address]} (Rating: #{place[:rating]} | Types: #{place[:types]})"
      end.join("\n")

      <<~PROMPT
        Select the best place from this list based on the given criteria.

        TARGET CITY: #{target_city}
        SPECIFIC PLACE: #{place_name || 'any relevant place'}

        OPTIONS:
        #{options_text}

        INSTRUCTIONS:
        1. Select the place that best matches the target city "#{target_city}"
        2. If there's a specific name "#{place_name}", prioritize places with similar names
        3. Consider geographic location (address should be in or near #{target_city})
        4. In case of tie, prefer the place with better rating
        5. Respond with ONLY the index number (0, 1, 2, etc.)

        Response (only the number):
      PROMPT
    end

    def build_area_extraction_prompt(address, city)
      <<~PROMPT
        Extract the neighborhood, district, or area name from this address.
        
        Address: "#{address}"
        City: #{city}
        
        Instructions:
        - Extract ONLY the area/neighborhood/district name
        - Do NOT include postal codes, numbers, or the main city name
        - If no specific area exists, respond "Center"
        - Respond in maximum 3 words
        - Use the same language as the address when possible
        
        Area name:
      PROMPT
    end

    def build_coordinates_prompt(city, interest)
      <<~PROMPT
        Provide approximate coordinates for the main cultural/tourist center of this city.
        
        City: #{city}
        Context: #{interest ? "User interested in #{interest}" : "General cultural center"}
        
        Provide:
        1. Latitude and longitude of the main historic/cultural center
        2. An appropriate name for the location
        
        Respond in JSON format:
        {
          "latitude": 00.0000,
          "longitude": 00.0000,
          "place_name": "Cultural Center Name"
        }
        
        JSON Response:
      PROMPT
    end

    # Response cleaners
    def clean_json_response(response)
      response.strip
              .gsub(/^```json\n?/, '')
              .gsub(/\n?```$/, '')
              .gsub(/^```\n?/, '')
              .gsub(/\n?```$/, '')
    end

    def clean_text_response(response)
      response.strip.gsub(/^["']|["']$/, '')
    end

    def generate_fallback_explanation(entity, parsed_vibe, language)
      interests_text = parsed_vibe[:interests]&.join(' y ') || 'experiencias culturales'
      city = parsed_vibe[:city] || 'la ciudad'
      
      case language
      when 'es'
        "Este lugar conecta perfectamente con tu búsqueda de #{interests_text} en #{city}."
      when 'fr'
        interests_text_fr = parsed_vibe[:interests]&.join(' et ') || 'expériences culturelles'
        "Cet endroit se connecte parfaitement avec votre recherche de #{interests_text_fr} à #{city}."
      when 'pt'
        interests_text_pt = parsed_vibe[:interests]&.join(' e ') || 'experiências culturais'
        "Este lugar se conecta perfeitamente com sua busca por #{interests_text_pt} em #{city}."
      when 'it'
        interests_text_it = parsed_vibe[:interests]&.join(' e ') || 'esperienze culturali'
        "Questo posto si collega perfettamente con la tua ricerca di #{interests_text_it} a #{city}."
      when 'de'
        interests_text_de = parsed_vibe[:interests]&.join(' und ') || 'kulturelle Erfahrungen'
        "Dieser Ort verbindet sich perfekt mit Ihrer Suche nach #{interests_text_de} in #{city}."
      else
        interests_text_en = parsed_vibe[:interests]&.join(' and ') || 'cultural experiences'
        "This place connects perfectly with your search for #{interests_text_en} in #{city}."
      end
    end
  end

  def get_curator_role(language)
    case language
    when 'es'
      "Eres un curador cultural experto."
    when 'fr'
      "Vous êtes un curateur culturel expert."
    when 'pt'
      "Você é um curador cultural especialista."
    when 'it'
      "Sei un curatore culturale esperto."
    when 'de'
      "Sie sind ein erfahrener Kulturkurator."
    else
      "You are an expert cultural curator."
    end
  end

    def get_prompts_config(language)
      case language
      when 'es'
        {
          'cultural_explanation' => 'Explica en un párrafo evocador (máximo 100 palabras) por qué este lugar es perfecto para %{action} su aventura cultural.',
          'connect_keywords' => 'Conecta los keywords de Qloo con la experiencia personal del usuario.',
          'tone_instruction' => 'Usa un tono cálido y poético.',
          'response_instruction' => 'Responde solo con el párrafo explicativo.'
        }
      when 'fr'
        {
          'cultural_explanation' => 'Expliquez dans un paragraphe évocateur (maximum 100 mots) pourquoi cet endroit est parfait pour %{action} leur aventure culturelle.',
          'connect_keywords' => 'Connectez les mots-clés de Qloo avec l\'expérience personnelle de l\'utilisateur.',
          'tone_instruction' => 'Utilisez un ton chaleureux et poétique.',
          'response_instruction' => 'Répondez seulement avec le paragraphe explicatif.'
        }
      when 'pt'
        {
          'cultural_explanation' => 'Explique em um parágrafo evocativo (máximo 100 palavras) por que este lugar é perfeito para %{action} sua aventura cultural.',
          'connect_keywords' => 'Conecte as palavras-chave do Qloo com a experiência pessoal do usuário.',
          'tone_instruction' => 'Use um tom caloroso e poético.',
          'response_instruction' => 'Responda apenas com o parágrafo explicativo.'
        }
      when 'it'
        {
          'cultural_explanation' => 'Spiega in un paragrafo evocativo (massimo 100 parole) perché questo posto è perfetto per %{action} la loro avventura culturale.',
          'connect_keywords' => 'Collega le parole chiave di Qloo con l\'esperienza personale dell\'utente.',
          'tone_instruction' => 'Usa un tono caldo e poetico.',
          'response_instruction' => 'Rispondi solo con il paragrafo esplicativo.'
        }
      when 'de'
        {
          'cultural_explanation' => 'Erklären Sie in einem eindringlichen Absatz (maximal 100 Wörter), warum dieser Ort perfekt ist, um %{action} ihr kulturelles Abenteuer.',
          'connect_keywords' => 'Verbinden Sie Qloo-Schlüsselwörter mit der persönlichen Erfahrung des Benutzers.',
          'tone_instruction' => 'Verwenden Sie einen warmen und poetischen Ton.',
          'response_instruction' => 'Antworten Sie nur mit dem erklärenden Absatz.'
        }
      else
        {
          'cultural_explanation' => 'Explain in an evocative paragraph (maximum 100 words) why this place is perfect to %{action} their cultural adventure.',
          'connect_keywords' => 'Connect Qloo keywords with the user\'s personal experience.',
          'tone_instruction' => 'Use a warm and poetic tone.',
          'response_instruction' => 'Respond only with the explanatory paragraph.'
        }
      end
  end

  def get_actions_config(language)
    case language
    when 'es'
      { 'begin' => 'comenzar', 'continue' => 'continuar', 'culminate' => 'culminar' }
    when 'fr'
      { 'begin' => 'commencer', 'continue' => 'continuer', 'culminate' => 'culminer' }
    when 'pt'
      { 'begin' => 'começar', 'continue' => 'continuar', 'culminate' => 'culminar' }
    when 'it'
      { 'begin' => 'iniziare', 'continue' => 'continuare', 'culminate' => 'culminare' }
    when 'de'
      { 'begin' => 'zu beginnen', 'continue' => 'fortzusetzen', 'culminate' => 'zu vollenden' }
    else
      { 'begin' => 'begin', 'continue' => 'continue', 'culminate' => 'culminate' }
    end
 end

  def get_context_labels(language)
    case language
    when 'es'
      {
        user_seeks: 'Usuario busca',
        place: 'Lugar',
        description: 'Descripción',
        keywords: 'Keywords culturales',
        connector: 'en'
      }
    when 'fr'
      {
        user_seeks: 'L\'utilisateur cherche',
        place: 'Lieu',
        description: 'Description',
        keywords: 'Mots-clés culturels',
        connector: 'à'
      }
    when 'pt'
      {
        user_seeks: 'Usuário busca',
        place: 'Local',
        description: 'Descrição',
        keywords: 'Palavras-chave culturais',
        connector: 'em'
      }
    when 'it'
      {
        user_seeks: 'L\'utente cerca',
        place: 'Posto',
        description: 'Descrizione',
        keywords: 'Parole chiave culturali',
        connector: 'a'
      }
    when 'de'
      {
        user_seeks: 'Benutzer sucht',
        place: 'Ort',
        description: 'Beschreibung',
        keywords: 'Kulturelle Schlüsselwörter',
        connector: 'in'
      }
    else
      {
        user_seeks: 'User seeks',
        place: 'Place',
        description: 'Description', 
        keywords: 'Cultural keywords',
        connector: 'in'
      }
    end
  end

  def get_fallback_config(language)
    {
      'cultural_curator_role' => get_curator_role(language),
      'prompts' => get_prompts_config(language),
      'experience_actions' => get_actions_config(language)
    }
  end

  def get_fallback_action(action_key, language)
    actions = get_actions_config(language)
    actions[action_key.to_s] || actions['begin']
  end

  def get_fallback_interests_text(language)
    case language
    when 'es' then 'experiencias culturales'
    when 'fr' then 'expériences culturelles'
    when 'pt' then 'experiências culturais'
    when 'it' then 'esperienze culturali'
    when 'de' then 'kulturelle Erfahrungen'
    else 'cultural experiences'
    end
  end
end
