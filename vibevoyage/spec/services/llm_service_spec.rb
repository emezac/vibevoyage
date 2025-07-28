
# spec/services/llm_service_spec.rb
require 'rails_helper'
require_relative '../../app/services/llm_service'

RSpec.describe LlmService do
  # Test the actual behavior without complex mocking
  describe '.detect_language' do
    it 'returns default language for blank text' do
      expect(LlmService.detect_language('')).to eq('en')
      expect(LlmService.detect_language(nil)).to eq('en')
    end

    it 'works with normal text' do
      result = LlmService.detect_language('Hello world')
      expect(['en', 'es', 'fr', 'pt', 'it', 'de']).to include(result)
    end

    it 'handles errors gracefully' do
      # Force an error by mocking Rails.cache to fail
      allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
      
      result = LlmService.detect_language('Some text')
      expect(result).to eq('en')
    end
  end

  describe '.parse_vibe' do
    let(:sample_vibe) { "A cultural evening in Paris with art and wine" }

    it 'returns hash with expected structure' do
      result = LlmService.parse_vibe(sample_vibe)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:city)
      expect(result).to have_key(:interests)
      expect(result).to have_key(:detected_language)
      expect(result[:city]).to be_a(String)
      expect(result[:interests]).to be_a(Array)
      expect(result[:detected_language]).to be_a(String)
    end

    it 'includes detected language' do
      result = LlmService.parse_vibe(sample_vibe)
      expect(['en', 'es', 'fr', 'pt', 'it', 'de']).to include(result[:detected_language])
    end

    it 'handles edge case with empty vibe' do
      result = LlmService.parse_vibe('')
      expect(result).to be_a(Hash)
      expect(result).to have_key(:detected_language)
    end
  end

  describe '.generate_cultural_explanation' do
    let(:entity) { { 'name' => 'Test Museum', 'properties' => { 'description' => 'Art museum' } } }
    let(:parsed_vibe) { { city: 'Paris', interests: ['art'], detected_language: 'en' } }
    let(:keywords) { ['contemporary', 'sculpture'] }

    it 'generates explanation string' do
      result = LlmService.generate_cultural_explanation(entity, parsed_vibe, keywords, 0)
      
      expect(result).to be_a(String)
      expect(result.length).to be > 10
    end

    it 'handles missing entity properties' do
      minimal_entity = { 'name' => 'Test Place' }
      result = LlmService.generate_cultural_explanation(minimal_entity, parsed_vibe, keywords, 0)
      
      expect(result).to be_a(String)
      expect(result.length).to be > 10
    end

    it 'handles different experience indices' do
      result1 = LlmService.generate_cultural_explanation(entity, parsed_vibe, keywords, 0)
      result2 = LlmService.generate_cultural_explanation(entity, parsed_vibe, keywords, 1)
      result3 = LlmService.generate_cultural_explanation(entity, parsed_vibe, keywords, 2)
      
      expect(result1).to be_a(String)
      expect(result2).to be_a(String) 
      expect(result3).to be_a(String)
    end
  end

  describe '.find_best_place_match' do
    let(:places_data) do
      [
        { name: 'Place 1', address: 'Address 1', rating: 4.5, types: ['museum'] },
        { name: 'Place 2', address: 'Address 2', rating: 4.0, types: ['restaurant'] }
      ]
    end

    it 'returns first place if only one exists' do
      single_place = [places_data.first]
      result = LlmService.find_best_place_match(single_place, 'Paris')
      expect(result).to eq(single_place.first)
    end

    it 'returns a place when multiple exist' do
      # Mock execute_llm_task to return a valid response for this test
      allow(LlmService).to receive(:execute_llm_task).and_return('0')
      
      result = LlmService.find_best_place_match(places_data, 'Paris', 'museum')
      
      expect(result).not_to be_nil
      expect(places_data).to include(result)
    end

    it 'handles empty array gracefully' do
      result = LlmService.find_best_place_match([], 'Paris')
      expect(result).to be_nil
    end

    it 'handles nil places_data gracefully' do
      result = LlmService.find_best_place_match(nil, 'Paris')
      expect(result).to be_nil
    end
  end

  describe '.extract_area_from_address' do
    it 'returns a string area name' do
      result = LlmService.extract_area_from_address('123 Rue de Montmartre, Paris', 'Paris')
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'returns Center as fallback' do
      result = LlmService.extract_area_from_address('', '')
      expect(result).to eq('Center')
    end

    it 'handles nil inputs' do
      result = LlmService.extract_area_from_address(nil, nil)
      expect(result).to eq('Center')
    end
  end

  describe '.generate_fallback_coordinates' do
    it 'returns coordinates hash' do
      result = LlmService.generate_fallback_coordinates('Paris', 'art')
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:latitude)
      expect(result).to have_key(:longitude)
      expect(result).to have_key(:place_name)
      expect(result[:latitude]).to be_a(Numeric)
      expect(result[:longitude]).to be_a(Numeric)
      expect(result[:place_name]).to be_a(String)
    end

    it 'handles missing city' do
      result = LlmService.generate_fallback_coordinates('', nil)
      
      expect(result).to be_a(Hash)
      expect(result[:latitude]).to be_a(Numeric)
      expect(result[:longitude]).to be_a(Numeric)
    end
  end

  describe 'private methods' do
    describe '.clean_json_response' do
      it 'cleans JSON response' do
        dirty_json = "```json\n{\"test\": \"value\"}\n```"
        clean_json = LlmService.send(:clean_json_response, dirty_json)
        expect(clean_json).to eq('{"test": "value"}')
      end

      it 'cleans simple JSON without markdown' do
        simple_json = '{"test": "value"}'
        clean_json = LlmService.send(:clean_json_response, simple_json)
        expect(clean_json).to eq('{"test": "value"}')
      end

      it 'handles empty strings' do
        clean_json = LlmService.send(:clean_json_response, '')
        expect(clean_json).to eq('')
      end
    end

    describe '.clean_text_response' do
      it 'cleans text response with quotes' do
        dirty_text = '"Some text with quotes"'
        clean_text = LlmService.send(:clean_text_response, dirty_text)
        expect(clean_text).to eq('Some text with quotes')
      end

      it 'leaves clean text unchanged' do
        clean_text_input = 'Some clean text'
        clean_text = LlmService.send(:clean_text_response, clean_text_input)
        expect(clean_text).to eq('Some clean text')
      end

      it 'handles empty strings' do
        clean_text = LlmService.send(:clean_text_response, '')
        expect(clean_text).to eq('')
      end
    end

    describe '.generate_fallback_explanation' do
      let(:entity) { { 'name' => 'Test Place' } }
      let(:parsed_vibe) { { city: 'Paris', interests: ['art', 'wine'] } }

      it 'generates fallback explanation in English' do
        result = LlmService.send(:generate_fallback_explanation, entity, parsed_vibe, 'en')
        expect(result).to include('This place connects perfectly')
        expect(result).to include('art and wine')
        expect(result).to include('Paris')
      end

      it 'generates fallback explanation in Spanish' do
        result = LlmService.send(:generate_fallback_explanation, entity, parsed_vibe, 'es')
        expect(result).to include('Este lugar conecta perfectamente')
        expect(result).to include('art y wine')
        expect(result).to include('Paris')
      end

      it 'generates fallback explanation in French' do
        result = LlmService.send(:generate_fallback_explanation, entity, parsed_vibe, 'fr')
        expect(result).to include('Cet endroit se connecte parfaitement')
        expect(result).to include('art et wine')
        expect(result).to include('Paris')
      end

      it 'handles empty interests' do
        empty_vibe = { city: 'Paris', interests: [] }
        result = LlmService.send(:generate_fallback_explanation, entity, empty_vibe, 'en')
        expect(result).to be_a(String)
        expect(result.length).to be > 10
      end

      it 'handles nil interests' do
        nil_vibe = { city: 'Paris', interests: nil }
        result = LlmService.send(:generate_fallback_explanation, entity, nil_vibe, 'en')
        expect(result).to be_a(String)
        expect(result).to include('Paris')
      end
    end

    describe '.generate_mock_response' do
      it 'returns appropriate mock for language detection' do
        prompt = "Detect the language of this text"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to eq('en')
      end

      it 'returns appropriate mock for vibe parsing' do
        prompt = "Analyze this cultural preference text"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to include('Test City')
      end

      it 'returns appropriate mock for place selection' do
        prompt = "Select the best place from this list"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to eq('0')
      end

      it 'returns appropriate mock for area extraction' do
        prompt = "Extract the neighborhood, district"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to eq('Montmartre')
      end

      it 'returns appropriate mock for coordinates' do
        prompt = "Provide approximate coordinates"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to include('latitude')
      end

      it 'returns generic mock for other prompts' do
        prompt = "Some other prompt"
        result = LlmService.send(:generate_mock_response, prompt)
        expect(result).to eq('Test explanation')
      end
    end
  end

  describe 'prompt builders' do
    describe '.build_language_detection_prompt' do
      it 'builds correct prompt' do
        prompt = LlmService.send(:build_language_detection_prompt, 'Hello world')
        expect(prompt).to include('Hello world')
        expect(prompt).to include('language code')
        expect(prompt).to include('es')
        expect(prompt).to include('en')
      end
    end

    describe '.build_vibe_parsing_prompt' do
      it 'builds correct prompt' do
        prompt = LlmService.send(:build_vibe_parsing_prompt, 'Cultural evening in Paris')
        expect(prompt).to include('Cultural evening in Paris')
        expect(prompt).to include('JSON')
        expect(prompt).to include('CITY')
        expect(prompt).to include('INTERESTS')
      end
    end

    describe '.build_place_matching_prompt' do
      let(:places_data) do
        [
          { name: 'Place 1', address: 'Address 1', rating: 4.5, types: ['museum'] }
        ]
      end

      it 'builds correct prompt' do
        prompt = LlmService.send(:build_place_matching_prompt, places_data, 'Paris', 'museum')
        expect(prompt).to include('Paris')
        expect(prompt).to include('museum')
        expect(prompt).to include('Place 1')
        expect(prompt).to include('Address 1')
      end
    end

    describe '.build_area_extraction_prompt' do
      it 'builds correct prompt' do
        prompt = LlmService.send(:build_area_extraction_prompt, '123 Main St, Paris', 'Paris')
        expect(prompt).to include('123 Main St, Paris')
        expect(prompt).to include('Paris')
        expect(prompt).to include('neighborhood')
      end
    end

    describe '.build_coordinates_prompt' do
      it 'builds correct prompt' do
        prompt = LlmService.send(:build_coordinates_prompt, 'Paris', 'art')
        expect(prompt).to include('Paris')
        expect(prompt).to include('art')
        expect(prompt).to include('coordinates')
        expect(prompt).to include('JSON')
      end
    end

    describe '.build_cultural_explanation_prompt' do
      let(:entity) { { 'name' => 'Test Museum', 'properties' => { 'description' => 'Art museum' } } }
      let(:parsed_vibe) { { city: 'Paris', interests: ['art'], detected_language: 'en' } }
      let(:keywords) { ['contemporary', 'sculpture'] }

      it 'builds correct prompt' do
        prompt = LlmService.send(:build_cultural_explanation_prompt,
          entity: entity,
          parsed_vibe: parsed_vibe,
          qloo_keywords: keywords,
          experience_index: 0,
          language: 'en'
        )
        expect(prompt).to include('Test Museum')
        expect(prompt).to include('Paris')
        expect(prompt).to include('art')
        expect(prompt).to include('contemporary')
        expect(prompt).to include('sculpture')
      end

      it 'handles missing entity properties' do
        minimal_entity = { 'name' => 'Test Museum' }
        prompt = LlmService.send(:build_cultural_explanation_prompt,
          entity: minimal_entity,
          parsed_vibe: parsed_vibe,
          qloo_keywords: keywords,
          experience_index: 0,
          language: 'en'
        )
        expect(prompt).to include('Test Museum')
        expect(prompt).to include('Cultural venue') # fallback description
      end

      it 'handles nil interests' do
        parsed_vibe_nil = { city: 'Paris', interests: nil, detected_language: 'en' }
        expect {
          LlmService.send(:build_cultural_explanation_prompt,
            entity: entity,
            parsed_vibe: parsed_vibe_nil,
            qloo_keywords: keywords,
            experience_index: 0,
            language: 'en'
          )
        }.not_to raise_error
      end
    end
  end

  describe 'integration tests' do
    it 'can process a complete workflow' do
      # Test that the main methods work together without breaking
      vibe = "Cultural exploration in Madrid"
      
      # Parse the vibe
      parsed = LlmService.parse_vibe(vibe)
      expect(parsed).to be_a(Hash)
      
      # Generate explanation
      entity = { 'name' => 'Prado Museum', 'properties' => { 'description' => 'Famous art museum' } }
      explanation = LlmService.generate_cultural_explanation(entity, parsed, ['art', 'culture'], 0)
      expect(explanation).to be_a(String)
      
      # Extract area
      area = LlmService.extract_area_from_address('Calle del Prado, Madrid', 'Madrid')
      expect(area).to be_a(String)
      
      # Generate coordinates
      coords = LlmService.generate_fallback_coordinates('Madrid', 'art')
      expect(coords).to be_a(Hash)
      expect(coords).to have_key(:latitude)
    end
  end
end