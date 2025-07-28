# spec/services/analytics_service_debug_spec.rb
require 'rails_helper'

RSpec.describe AnalyticsService, "Debug Tests" do
  before(:each) do
    # Mock minimal dependencies
    allow(Rails.cache).to receive(:write)
    allow(Rails.cache).to receive(:read).and_return([])
    allow(Rails.logger).to receive(:info)
    allow(Time).to receive(:current).and_return(Time.parse("2024-01-01 12:00:00"))
    allow(Date).to receive(:current).and_return(Date.parse("2024-01-01"))
  end

  describe "Debug individual methods" do
    let(:experiences) do
      [
        { qloo_entity_id: 'test1', latitude: 40.0, longitude: -3.0, vibe_match: 85 },
        { qloo_entity_id: nil, latitude: nil, longitude: nil, vibe_match: 75 }
      ]
    end

    it "debug calculate_coordinates_coverage" do
      puts "\n=== DEBUGGING calculate_coordinates_coverage ==="
      
      begin
        result = AnalyticsService.send(:calculate_coordinates_coverage, experiences)
        puts "✅ Result: #{result.inspect}"
        puts "✅ Type: #{result.class}"
        
        # Manual calculation
        with_coords = experiences.count { |exp| exp[:latitude].present? && exp[:longitude].present? }
        puts "✅ with_coords: #{with_coords}"
        puts "✅ total experiences: #{experiences.size}"
        manual_result = (with_coords.to_f / experiences.size * 100).round(1)
        puts "✅ manual calculation: #{manual_result}"
        
      rescue => e
        puts "❌ Error: #{e.message}"
        puts "❌ Backtrace: #{e.backtrace.first(3)}"
      end
    end

    it "debug calculate_average_vibe_match" do
      puts "\n=== DEBUGGING calculate_average_vibe_match ==="
      
      begin
        result = AnalyticsService.send(:calculate_average_vibe_match, experiences)
        puts "✅ Result: #{result.inspect}"
        puts "✅ Type: #{result.class}"
        
        # Manual calculation
        total_match = experiences.sum { |exp| exp[:vibe_match] || 0 }
        puts "✅ total_match: #{total_match}"
        manual_result = (total_match.to_f / experiences.size).round(1)
        puts "✅ manual calculation: #{manual_result}"
        
      rescue => e
        puts "❌ Error: #{e.message}"
        puts "❌ Backtrace: #{e.backtrace.first(3)}"
      end
    end

    it "debug full track_journey_processing execution" do
      puts "\n=== DEBUGGING track_journey_processing ==="
      
      process_id = 'test_123'
      user_vibe = 'A cultural evening in Madrid'
      parsed_vibe = { detected_language: 'es', city: 'Madrid', interests: ['culture'] }
      duration = 2.5

      # Spy on internal method calls
      allow(AnalyticsService).to receive(:store_journey_metrics) do |metrics|
        puts "📊 store_journey_metrics called with:"
        puts "   process_id: #{metrics[:process_id]}"
        puts "   coordinates_coverage: #{metrics[:coordinates_coverage]}"
        puts "   vibe_match_average: #{metrics[:vibe_match_average]}"
        metrics
      end

      begin
        puts "🚀 Calling track_journey_processing..."
        result = AnalyticsService.track_journey_processing(process_id, user_vibe, parsed_vibe, experiences, duration)
        
        puts "✅ Method completed!"
        puts "✅ Result type: #{result.class}"
        puts "✅ Result keys: #{result&.keys}"
        puts "✅ coordinates_coverage: #{result&.dig(:coordinates_coverage)}"
        puts "✅ vibe_match_average: #{result&.dig(:vibe_match_average)}"
        
      rescue => e
        puts "❌ Error in track_journey_processing: #{e.message}"
        puts "❌ Backtrace: #{e.backtrace.first(5)}"
      end
    end

    it "debug method existence" do
      puts "\n=== DEBUGGING method existence ==="
      
      methods_to_check = [
        :track_journey_processing,
        :calculate_coordinates_coverage,
        :calculate_average_vibe_match,
        :store_journey_metrics
      ]
      
      methods_to_check.each do |method|
        if AnalyticsService.respond_to?(method, true) # true includes private methods
          puts "✅ #{method} exists"
        else
          puts "❌ #{method} does not exist"
        end
      end
    end
  end
end
