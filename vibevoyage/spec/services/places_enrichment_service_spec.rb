# spec/services/places_enrichment_service_spec.rb
require 'rails_helper'

RSpec.describe PlacesEnrichmentService do
  describe '.validate_coordinates' do
    it 'validates correct coordinates' do
      result = PlacesEnrichmentService.validate_coordinates(40.4168, -3.7038)
      
      expect(result[:valid]).to be true
      expect(result[:latitude]).to eq(40.4168)
      expect(result[:longitude]).to eq(-3.7038)
    end

    it 'rejects invalid coordinates' do
      invalid_cases = [
        [nil, nil],
        [0, 0],
        [91, 0], # Latitude out of range
        [0, 181], # Longitude out of range
        ['invalid', 'coords']
      ]

      invalid_cases.each do |lat, lon|
        result = PlacesEnrichmentService.validate_coordinates(lat, lon)
        expect(result[:valid]).to be false
      end
    end
  end

  describe '.calculate_distance' do
    it 'calculates distance correctly' do
      # Known distance: Madrid to Barcelona ~500km
      distance = PlacesEnrichmentService.calculate_distance(40.4168, -3.7038, 41.3851, 2.1734)
      expect(distance).to be_between(500, 600)
    end

    it 'returns infinity for invalid coordinates' do
      distance = PlacesEnrichmentService.calculate_distance(nil, nil, 40.0, -3.0)
      expect(distance).to eq(Float::INFINITY)
    end
  end

  describe '.generate_place_metadata' do
    let(:google_data) do
      {
        'name' => 'Test Place',
        'rating' => 4.5,
        'formatted_phone_number' => '+123456789',
        'website' => 'http://test.com',
        'geometry' => { 'location' => { 'lat' => 40.0, 'lng' => -3.0 } }
      }
    end

    let(:qloo_entity) do
      {
        'name' => 'Test Place',
        'location' => { 'lat' => 40.0, 'lon' => -3.0 },
        'properties' => { 'description' => 'Great place' }
      }
    end

    it 'generates comprehensive metadata' do
      metadata = PlacesEnrichmentService.generate_place_metadata(google_data, qloo_entity)
      
      expect(metadata[:data_sources]).to include('google_places', 'qloo')
      expect(metadata[:data_quality]).to be_in(['low', 'medium', 'high', 'very_low'])
      expect(metadata[:verification_status]).to eq('cross_verified')
      expect(metadata[:coordinate_source]).to eq('google_places')
      expect(metadata[:last_enriched]).to be_present
    end

    it 'handles missing data gracefully' do
      metadata = PlacesEnrichmentService.generate_place_metadata(nil, qloo_entity)
      
      expect(metadata[:data_sources]).to eq(['qloo'])
      expect(metadata[:verification_status]).to eq('qloo_verified')
      expect(metadata[:coordinate_source]).to eq('qloo')
    end
  end

  describe '.create_google_data_from_qloo' do
    let(:qloo_entity) do
      {
        'name' => 'Test Restaurant',
        'entity_id' => 'qloo_123',
        'properties' => {
          'address' => '123 Test Street',
          'business_rating' => 4.2,
          'website' => 'http://test.com'
        },
        'tags' => [{ 'name' => 'restaurant', 'type' => 'category' }]
      }
    end

    let(:coordinates) { { 'lat' => 40.0, 'lng' => -3.0 } }

    it 'creates Google Places compatible data structure' do
      result = PlacesEnrichmentService.create_google_data_from_qloo(qloo_entity, coordinates)
      
      expect(result['name']).to eq('Test Restaurant')
      expect(result['place_id']).to eq('qloo_123')
      expect(result['rating']).to eq(4.2)
      expect(result['geometry']['location']).to eq(coordinates)
      expect(result['types']).to include('restaurant', 'establishment')
      expect(result['website']).to eq('http://test.com')
    end
  end
end
