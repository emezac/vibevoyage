# spec/services/localization_service_spec.rb
require 'rails_helper'

RSpec.describe LocalizationService do
  describe '.detect_language' do
    context 'with pattern-based detection' do
      it 'detects Spanish correctly' do
        spanish_text = "Una tarde contemplativa en Ciudad de México"
        expect(LocalizationService.detect_language(spanish_text)).to eq('es')
      end

      it 'detects English correctly' do
        english_text = "A contemplative afternoon with the cultural scene"
        expect(LocalizationService.detect_language(english_text)).to eq('en')
      end

      it 'detects Portuguese over Spanish for ambiguous text' do
        text = "Uma tarde com cultura" # Contains 'uma' and 'com' (both languages) but 'cultura' is more Portuguese-specific
        expect(LocalizationService.detect_language(text)).to eq('pt')
      end

      it 'detects Spanish over Portuguese for shared keywords' do
        text = "Una ciudad con cultura" # Contains 'con' and 'cultura'
        expect(LocalizationService.detect_language(text)).to eq('es')
      end

      it 'detects Portuguese with unique keywords' do
        text = "Uma experiência em São Paulo"
        expect(LocalizationService.detect_language(text)).to eq('pt')
      end

      it 'prioritizes Spanish over Portuguese for ambiguous text' do
        text = "Cultura en la ciudad"
        expect(LocalizationService.detect_language(text)).to eq('es')
      end

      it 'detects Spanish with unique keywords' do
        text = "Qué ciudad tan hermosa"
        expect(LocalizationService.detect_language(text)).to eq('es')
      end

      it 'detects Portuguese with additional unique keywords' do
        text = "Você explora a cultura"
        expect(LocalizationService.detect_language(text)).to eq('pt')
      end

      it 'handles mixed case text correctly' do
        text = "Uma Tarde em SÃO PAULO com Experiência Cultural"
        expect(LocalizationService.detect_language(text)).to eq('pt')
      end

      it 'detects French correctly' do
        french_text = "Une soirée à Paris avec du vin"
        expect(LocalizationService.detect_language(french_text)).to eq('fr')
      end

      it 'detects Portuguese correctly' do
        portuguese_text = "Uma tarde em São Paulo com uma experiência cultural"
        expect(LocalizationService.detect_language(portuguese_text)).to eq('pt')
      end

      it 'detects Italian correctly' do
        italian_text = "Una serata culturale a Roma dove mangiare"
        expect(LocalizationService.detect_language(italian_text)).to eq('it')
      end

      it 'detects German correctly' do
        german_text = "Ein kultureller Abend mit lokalen Spezialitäten"
        expect(LocalizationService.detect_language(german_text)).to eq('de')
      end
    end

    it 'returns default language for empty text' do
      expect(LocalizationService.detect_language("")).to eq('en')
      expect(LocalizationService.detect_language(nil)).to eq('en')
    end

    context 'with LLM fallback' do
      before do
        # Mock LLM service for specific tests
        if defined?(LLMService)
          allow(LLMService).to receive(:detect_language).and_return('de')
        end
      end

      it 'falls back to LLM detection for ambiguous text' do
        ambiguous_text = "Test text without clear language indicators xyz"
        result = LocalizationService.detect_language(ambiguous_text)
        # Should either be 'en' (default) or 'de' (from LLM mock)
        expect(['en', 'de']).to include(result)
      end

      it 'handles LLM service errors gracefully' do
        if defined?(LLMService)
          allow(LLMService).to receive(:detect_language).and_raise(StandardError.new("API Error"))
        end
        ambiguous_text = "Some text that needs LLM detection"
        expect(LocalizationService.detect_language(ambiguous_text)).to eq('en')
      end

      it 'prioritizes pattern detection over LLM' do
        # Even if LLM would return something else, pattern detection should win
        if defined?(LLMService)
          allow(LLMService).to receive(:detect_language).and_return('fr')
        end
        spanish_text = "Una ciudad con mucha cultura"
        expect(LocalizationService.detect_language(spanish_text)).to eq('es')
      end
    end
  end

  describe '.supported_language?' do
    it 'returns true for supported languages' do
      %w[es en fr pt it de].each do |lang|
        expect(LocalizationService.supported_language?(lang)).to be true
      end
    end

    it 'returns false for unsupported languages' do
      %w[xx ja zh ar].each do |lang|
        expect(LocalizationService.supported_language?(lang)).to be false
      end
    end

    it 'handles different case inputs' do
      expect(LocalizationService.supported_language?('ES')).to be true
      expect(LocalizationService.supported_language?('En')).to be true
      expect(LocalizationService.supported_language?('FR')).to be true
    end
  end

  describe '.normalize_language' do
    it 'normalizes language codes correctly' do
      expect(LocalizationService.normalize_language('ES')).to eq('es')
      expect(LocalizationService.normalize_language('  en  ')).to eq('en')
      expect(LocalizationService.normalize_language('FR')).to eq('fr')
    end

    it 'returns default for invalid languages' do
      expect(LocalizationService.normalize_language('xx')).to eq('en')
      expect(LocalizationService.normalize_language('')).to eq('en')
      expect(LocalizationService.normalize_language(nil)).to eq('en')
    end
  end

  describe '.localize' do
    it 'returns localized content for valid keys' do
      result = LocalizationService.localize('narrative_labels.adventure_title', 'es')
      expect(result).to eq('Tu Aventura Cultural en')
    end

    it 'handles nested keys correctly' do
      result = LocalizationService.localize('time_periods.morning', 'es')
      expect(result).to eq('Mañana:')
      
      result = LocalizationService.localize('experience_descriptors.discovery', 'en')
      expect(result).to eq('Cultural Discovery')
    end

    it 'handles interpolations correctly' do
      result = LocalizationService.localize(
        'prompts.cultural_explanation', 
        'es', 
        action: 'comenzar'
      )
      expect(result).to include('comenzar')
    end

    it 'returns missing key indicator for nonexistent translations' do
      result = LocalizationService.localize('nonexistent.key', 'es')
      expect(result).to eq('[Missing: nonexistent.key]')
    end

    it 'falls back to default language for unsupported language' do
      result = LocalizationService.localize('narrative_labels.adventure_title', 'unsupported')
      expect(result).to eq('Your Cultural Adventure in')
    end

    it 'handles interpolation errors gracefully' do
      # This should not crash even if interpolation fails
      result = LocalizationService.localize(
        'prompts.cultural_explanation', 
        'es', 
        wrong_key: 'value'
      )
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'works with symbol keys' do
      result = LocalizationService.localize(:narrative_labels, 'es')
      expect(result).to be_a(Hash)
      # Corrige la clave de String a Símbolo
      expect(result).to include(:adventure_title) 
    end
  end

  describe '.adventure_title' do
    it 'generates correct titles for all supported languages' do
      city = 'Paris'
      
      expect(LocalizationService.adventure_title(city, 'es')).to eq('Tu Aventura Cultural en Paris')
      expect(LocalizationService.adventure_title(city, 'en')).to eq('Your Cultural Adventure in Paris')
      expect(LocalizationService.adventure_title(city, 'fr')).to eq('Votre Aventure Culturelle à Paris')
      expect(LocalizationService.adventure_title(city, 'pt')).to eq('Sua Aventura Cultural em Paris')
      expect(LocalizationService.adventure_title(city, 'it')).to eq('La Tua Avventura Culturale a Paris')
      expect(LocalizationService.adventure_title(city, 'de')).to eq('Ihr Kulturelles Abenteuer in Paris')
    end

    it 'handles cities with special characters' do
      city = 'São Paulo'
      result = LocalizationService.adventure_title(city, 'pt')
      expect(result).to include('São Paulo')
      expect(result).to eq('Sua Aventura Cultural em São Paulo')
    end
  end

  describe '.experience_title' do
    it 'generates correct experience titles' do
      expect(LocalizationService.experience_title(:morning, :discovery, 'es')).to eq('Mañana: Descubrimiento Cultural')
      expect(LocalizationService.experience_title(:afternoon, :immersion, 'en')).to eq('Afternoon: Authentic Immersion')
      expect(LocalizationService.experience_title(:evening, :culmination, 'fr')).to eq('Soir: Culmination Parfaite')
    end

    it 'falls back gracefully for invalid keys' do
      result = LocalizationService.experience_title(:invalid, :discovery, 'es')
      # Busca la palabra correcta en español
      expect(result).to include('Descubrimiento')
      # Y también que la parte que falla se muestre como tal
      expect(result).to start_with('[Missing: time_periods.invalid]') 
    end
  end

  describe '.cultural_location' do
    it 'generates localized location names' do
      expect(LocalizationService.cultural_location(:cultural_center, 'Madrid', 'es')).to eq('Centro Cultural de Madrid')
      expect(LocalizationService.cultural_location(:traditional_restaurant, 'Paris', 'fr')).to eq('Restaurant Traditionnel Paris')
      expect(LocalizationService.cultural_location(:nocturnal_space, 'Rome', 'it')).to eq('Spazio Culturale Notturno Rome')
    end
  end

  describe '.success_message' do
    it 'returns correct success messages' do
      expect(LocalizationService.success_message(offline: false, language: 'es')).to eq('¡Tu aventura cultural está lista!')
      expect(LocalizationService.success_message(offline: true, language: 'en')).to eq('Your adventure is ready! (Offline mode)')
      expect(LocalizationService.success_message(offline: false, language: 'fr')).to eq('Votre aventure culturelle est prête!')
    end
  end

  describe '.generate_fallback_experiences' do
    let(:city) { 'Madrid' }
    let(:interests) { ['restaurant', 'museum'] }
    let(:language) { 'es' }

    it 'generates the correct number of experiences' do
      experiences = LocalizationService.generate_fallback_experiences(city, interests, language)
      expect(experiences.size).to eq(3)
    end

    it 'includes required fields for each experience' do
      experiences = LocalizationService.generate_fallback_experiences(city, interests, language)
      
      experiences.each do |exp|
        expect(exp).to include(:time, :title, :location, :description, :cultural_explanation)
        expect(exp).to include(:duration, :area, :vibe_match, :rating, :image)
        expect(exp).to include(:qloo_keywords, :why_chosen)
        
        expect(exp[:title]).to be_present
        expect(exp[:location]).to include(city)
        expect(exp[:time]).to be_present
        expect(exp[:vibe_match]).to be_a(Numeric)
        expect(exp[:rating]).to be_a(Numeric)
      end
    end

    it 'localizes experience content correctly' do
      es_experiences = LocalizationService.generate_fallback_experiences(city, interests, 'es')
      en_experiences = LocalizationService.generate_fallback_experiences(city, interests, 'en')
      fr_experiences = LocalizationService.generate_fallback_experiences(city, interests, 'fr')
      
      expect(es_experiences.first[:title]).to include('Mañana:')
      expect(en_experiences.first[:title]).to include('Morning:')
      expect(fr_experiences.first[:title]).to include('Matin:')
      
      expect(es_experiences.first[:area]).to eq('Centro')
      expect(en_experiences.first[:area]).to eq('Center')
      expect(fr_experiences.first[:area]).to eq('Centre')
    end

    it 'generates unique content for each experience' do
      experiences = LocalizationService.generate_fallback_experiences(city, interests, language)
      
      titles = experiences.map { |exp| exp[:title] }
      expect(titles.uniq).to eq(titles) # All titles should be unique
      
      times = experiences.map { |exp| exp[:time] }
      expect(times.uniq).to eq(times) # All times should be unique
      
      areas = experiences.map { |exp| exp[:area] }
      expect(areas.uniq.size).to be >= 2 # Should have at least 2 different areas
    end

    it 'includes proper vibe match scores' do
      experiences = LocalizationService.generate_fallback_experiences(city, interests, language)
      
      experiences.each do |exp|
        expect(exp[:vibe_match]).to be_between(75, 100)
      end
    end

    it 'includes proper ratings' do
      experiences = LocalizationService.generate_fallback_experiences(city, interests, language)
      
      experiences.each do |exp|
        expect(exp[:rating]).to be_between(3.0, 5.0)
      end
    end
  end

  describe '.build_narrative_html' do
    let(:user_vibe) { 'Test cultural vibe' }
    let(:city) { 'Barcelona' }
    let(:interests) { ['art', 'food'] }
    let(:experiences_count) { 3 }

    it 'generates valid HTML for all languages' do
      %w[es en fr pt it de].each do |language|
        html = LocalizationService.build_narrative_html(
          user_vibe, city, interests, experiences_count, language
        )
        
        expect(html).to include('<div class="narrative')
        expect(html).to include(city)
        expect(html).to include(user_vibe)
        expect(html).to include('</div>') # Ensure HTML is properly closed
      end
    end

    it 'includes localized labels for Spanish' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'es'
      )
      
      expect(html).to include('Tu Aventura Cultural en')
      expect(html).to include('Tu vibe original:')
      expect(html).to include('Destino Identificado')
      expect(html).to include('Intereses Detectados')
      expect(html).to include('Curación Inteligente')
    end

    it 'includes localized labels for English' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'en'
      )
      
      expect(html).to include('Your Cultural Adventure in')
      expect(html).to include('Your original vibe:')
      expect(html).to include('Identified Destination')
      expect(html).to include('Detected Interests')
      expect(html).to include('Intelligent Curation')
    end

    it 'includes localized labels for French' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'fr'
      )
      
      expect(html).to include('Votre Aventure Culturelle à')
      expect(html).to include('Votre vibe original:')
      expect(html).to include('Destination Identifiée')
      expect(html).to include('Intérêts Détectés')
      expect(html).to include('Curation Intelligente')
    end

    it 'properly formats interests list' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'en'
      )
      
      expect(html).to include('art, food')
    end

    it 'includes proper CSS classes for styling' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'en'
      )
      
      expect(html).to include('glass-card')
      expect(html).to include('gradient-text')
      expect(html).to include('bg-gradient-to-br')
    end

    it 'handles potentially malicious user input safely' do
      malicious_vibe = '<script>alert("xss")</script>'
      html = LocalizationService.build_narrative_html(
        malicious_vibe, city, interests, experiences_count, 'en'
      )
      
      expect(html).to be_a(String)
      expect(html).to include('<div class="narrative')
      
      # Verify that the malicious input is properly escaped (safe)
      expect(html).to include('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
      
      # Verify that the raw malicious script is NOT present (would be unsafe)
      expect(html).not_to include('<script>alert("xss")</script>')
    end

    it 'handles empty interests gracefully' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, [], experiences_count, 'en'
      )
      
      expect(html).to be_a(String)
      expect(html).to include('<div class="narrative')
    end

    it 'includes experience count in description' do
      html = LocalizationService.build_narrative_html(
        user_vibe, city, interests, experiences_count, 'en'
      )
      
      expect(html).to include(experiences_count.to_s)
    end
  end

  # Additional edge case tests
  describe 'edge cases and error handling' do
    it 'handles nil inputs gracefully' do
      expect { LocalizationService.adventure_title(nil, 'es') }.not_to raise_error
      expect { LocalizationService.localize(nil, 'es') }.not_to raise_error
      expect { LocalizationService.generate_fallback_experiences('City', nil, 'es') }.not_to raise_error
    end

    it 'handles empty string inputs' do
      result = LocalizationService.adventure_title('', 'es')
      expect(result).to include('Tu Aventura Cultural en ')
      
      experiences = LocalizationService.generate_fallback_experiences('', [], 'es')
      expect(experiences.size).to eq(3)
    end

    it 'maintains consistency across multiple calls' do
      # Same inputs should produce same outputs
      result1 = LocalizationService.localize('narrative_labels.adventure_title', 'es')
      result2 = LocalizationService.localize('narrative_labels.adventure_title', 'es')
      expect(result1).to eq(result2)
      
      exp1 = LocalizationService.generate_fallback_experiences('Madrid', ['art'], 'es')
      exp2 = LocalizationService.generate_fallback_experiences('Madrid', ['art'], 'es')
      expect(exp1.first[:title]).to eq(exp2.first[:title])
    end

    context 'when external services are unavailable' do
      it 'still works for language detection with pattern matching' do
        result = LocalizationService.detect_language("Una ciudad hermosa")
        expect(result).to eq('es') # Should use pattern detection
      end

      it 'still generates fallback experiences' do
        experiences = LocalizationService.generate_fallback_experiences('Madrid', ['art'], 'es')
        expect(experiences.size).to eq(3)
        expect(experiences.first[:title]).to include('Mañana:')
      end

      it 'handles service unavailability gracefully' do
        # Test that the service doesn't crash when external dependencies fail
        expect { LocalizationService.detect_language("text without clear patterns") }.not_to raise_error
        expect { LocalizationService.generate_fallback_experiences('City', ['interest'], 'en') }.not_to raise_error
      end
    end
  end
end