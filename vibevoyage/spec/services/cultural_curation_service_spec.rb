# spec/services/cultural_curation_service_spec.rb
require 'rails_helper'

RSpec.describe CulturalCurationService do
  describe '.curate_experiences' do
    let(:parsed_vibe) do
      {
        city: 'Madrid',
        interests: ['restaurant', 'museum'],
        detected_language: 'es'
      }
    end

    context 'with Qloo data' do
      let(:qloo_data) do
        {
          'results' => {
            'entities' => [
              {
                'name' => 'Test Restaurant',
                'entity_id' => 'qloo_123',
                'popularity' => 0.8,
                'location' => { 'lat' => 40.4168, 'lon' => -3.7038 },
                'properties' => {
                  'description' => 'Amazing local cuisine',
                  'website' => 'http://test.com'
                },
                'tags' => [{ 'name' => 'Spanish cuisine', 'type' => 'category' }]
              }
            ]
          }
        }
      end

      it 'creates experiences from Qloo entities' do
        experiences = CulturalCurationService.curate_experiences(parsed_vibe, qloo_data)
        
        expect(experiences.size).to eq(1)
        
        experience = experiences.first
        expect(experience[:location]).to eq('Test Restaurant')
        expect(experience[:qloo_entity_id]).to eq('qloo_123')
        expect(experience[:latitude]).to eq(40.4168)
        expect(experience[:longitude]).to eq(-3.7038)
        expect(experience[:website]).to eq('http://test.com')
      end

      it 'generates localized titles' do
        experiences = CulturalCurationService.curate_experiences(parsed_vibe, qloo_data)
        
        expect(experiences.first[:title]).to include('Mañana:') # Spanish morning
      end
    end

    context 'without Qloo data' do
      it 'returns fallback experiences' do
        allow(LocalizationService).to receive(:generate_fallback_experiences).and_return([
          { title: 'Fallback Experience', location: 'Test Location' }
        ])

        experiences = CulturalCurationService.curate_experiences(parsed_vibe, nil)
        
        expect(LocalizationService).to have_received(:generate_fallback_experiences).with(
          'Madrid', ['restaurant', 'museum'], 'es'
        )
      end
    end
  end

  describe '.calculate_vibe_match' do
    let(:qloo_entity) { { 'popularity' => 0.8, 'tags' => [] } }
    let(:parsed_vibe) { { interests: ['restaurant', 'bar'] } }
    let(:keywords) { ['restaurant', 'fine_dining'] } 

    it 'calculates base score from popularity' do
      score = CulturalCurationService.calculate_vibe_match(qloo_entity, parsed_vibe, keywords)
      expect(score).to be >= 75 # Minimum score
      expect(score).to be <= 100
    end

    it 'adds bonus for keyword matches' do
      score_with_match = CulturalCurationService.calculate_vibe_match(qloo_entity, parsed_vibe, keywords)
      score_without_match = CulturalCurationService.calculate_vibe_match(qloo_entity, parsed_vibe, [])
      
      expect(score_with_match).to be > score_without_match
    end
  end

  describe '.extract_enhanced_qloo_data' do
    let(:qloo_entity) do
      {
        'properties' => {
          'website' => 'http://example.com',
          'phone' => '+1234567890',
          'keywords' => ['test', 'venue']
        },
        'location' => { 'lat' => 40.0, 'lon' => -3.0 },
        'tags' => [{ 'name' => 'restaurant', 'type' => 'category' }]
      }
    end

    it 'extracts all relevant data' do
      result = CulturalCurationService.extract_enhanced_qloo_data(qloo_entity)
      
      expect(result[:coordinates][:latitude]).to eq(40.0)
      expect(result[:coordinates][:longitude]).to eq(-3.0)
      expect(result[:contact][:website]).to eq('http://example.com')
      expect(result[:contact][:phone]).to eq('+1234567890')
      expect(result[:keywords]).to include('test', 'venue')
      expect(result[:categorization][:categories]).to include('restaurant')
    end
  end

  describe '.calculate_distance' do
    it 'calculates correct distance between coordinates' do
      # Madrid to Barcelona (approximately 500km)
      madrid_lat, madrid_lon = 40.4168, -3.7038
      barcelona_lat, barcelona_lon = 41.3851, 2.1734
      
      distance = CulturalCurationService.calculate_distance(
        madrid_lat, madrid_lon, barcelona_lat, barcelona_lon
      )
      
      expect(distance).to be_between(500, 600) # Approximate distance
    end

    it 'returns infinity for invalid coordinates' do
      distance = CulturalCurationService.calculate_distance(nil, nil, 40.0, -3.0)
      expect(distance).to eq(Float::INFINITY)
    end
  end
end
