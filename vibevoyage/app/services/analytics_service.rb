# app/services/analytics_service.rb
class AnalyticsService
  METRICS_CACHE_TTL = 1.hour
  
  class << self
    # Track journey processing metrics
    def track_journey_processing(process_id, user_vibe, parsed_vibe, experiences, duration)
      metrics = {
        process_id: process_id,
        user_vibe_length: user_vibe.length,
        detected_language: parsed_vibe[:detected_language],
        city: parsed_vibe[:city],
        interests_count: parsed_vibe[:interests]&.size || 0,
        experiences_count: experiences.size,
        processing_duration: duration,
        timestamp: Time.current.iso8601,
        has_qloo_data: experiences.any? { |exp| exp[:qloo_entity_id].present? },
        coordinates_coverage: calculate_coordinates_coverage(experiences),
        vibe_match_average: calculate_average_vibe_match(experiences),
        data_quality_score: calculate_data_quality_score(experiences)
      }
      
      store_journey_metrics(metrics)
      update_language_usage_stats(parsed_vibe[:detected_language])
      update_city_popularity_stats(parsed_vibe[:city])
      
      Rails.logger.info "📊 Journey metrics tracked for process_id: #{process_id}"
      metrics
    end

    # Track LLM service performance
    def track_llm_performance(operation, duration, success, language = nil, error = nil)
      metrics = {
        operation: operation,
        duration_ms: (duration * 1000).round(2),
        success: success,
        language: language,
        error_type: error&.class&.name,
        error_message: error&.message&.truncate(100),
        timestamp: Time.current.iso8601
      }
      
      store_llm_metrics(metrics)
      update_llm_performance_stats(operation, duration, success)
      
      metrics
    end

    # Track cultural curation effectiveness
    def track_curation_effectiveness(experiences, user_feedback = nil)
      metrics = {
        total_experiences: experiences.size,
        qloo_sourced: experiences.count { |exp| exp[:qloo_entity_id].present? },
        google_sourced: experiences.count { |exp| exp[:google_maps_url].present? },
        fallback_count: experiences.count { |exp| exp[:qloo_entity_id].nil? && exp[:google_maps_url].nil? },
        average_vibe_match: calculate_average_vibe_match(experiences),
        keyword_density: calculate_keyword_density(experiences),
        user_feedback: user_feedback,
        timestamp: Time.current.iso8601
      }
      
      store_curation_metrics(metrics)
      metrics
    end

    # Get performance dashboard data
    def get_performance_dashboard(timeframe = '24h')
      cache_key = "analytics:dashboard:#{timeframe}"
      
      Rails.cache.fetch(cache_key, expires_in: METRICS_CACHE_TTL) do
        build_performance_dashboard(timeframe)
      end
    end

    # Get language usage statistics
    def get_language_stats(timeframe = '7d')
      cache_key = "analytics:language_stats:#{timeframe}"
      
      Rails.cache.fetch(cache_key, expires_in: METRICS_CACHE_TTL) do
        build_language_stats(timeframe)
      end
    end

    # Get city popularity rankings
    def get_city_rankings(timeframe = '30d', limit = 10)
      cache_key = "analytics:city_rankings:#{timeframe}:#{limit}"
      
      Rails.cache.fetch(cache_key, expires_in: METRICS_CACHE_TTL) do
        build_city_rankings(timeframe, limit)
      end
    end

    # Get service health metrics
    def get_service_health
      {
        localization_service: check_localization_service_health,
        llm_service: check_llm_service_health,
        cultural_curation_service: check_curation_service_health,
        places_enrichment_service: check_places_service_health,
        overall_status: calculate_overall_health_status
      }
    end

    # Generate detailed analytics report
    def generate_analytics_report(start_date, end_date)
      {
        summary: build_summary_metrics(start_date, end_date),
        language_analysis: build_language_analysis(start_date, end_date),
        performance_analysis: build_performance_analysis(start_date, end_date),
        quality_analysis: build_quality_analysis(start_date, end_date),
        user_behavior: build_user_behavior_analysis(start_date, end_date),
        recommendations: generate_optimization_recommendations(start_date, end_date)
      }
    end

    # Track errors and issues
    def track_error(service, operation, error, context = {})
      error_data = {
        service: service,
        operation: operation,
        error_class: error.class.name,
        error_message: error.message,
        stack_trace: error.backtrace&.first(5),
        context: context.slice(:process_id, :language, :city, :user_vibe_length),
        timestamp: Time.current.iso8601,
        severity: determine_error_severity(error)
      }
      
      store_error_metrics(error_data)
      alert_if_critical_error(error_data)
      
      error_data
    end

    private

    # Calculation methods
    def calculate_coordinates_coverage(experiences)
      with_coords = experiences.count { |exp| exp[:latitude].present? && exp[:longitude].present? }
      return 0 if experiences.empty?
      
      (with_coords.to_f / experiences.size * 100).round(1)
    end

    def calculate_average_vibe_match(experiences)
      return 0 if experiences.empty?
      
      total_match = experiences.sum { |exp| exp[:vibe_match] || 0 }
      (total_match.to_f / experiences.size).round(1)
    end

    def calculate_data_quality_score(experiences)
      return 0 if experiences.empty?
      
      quality_scores = experiences.map do |exp|
        score = 0
        score += 25 if exp[:qloo_entity_id].present?
        score += 25 if exp[:latitude].present? && exp[:longitude].present?
        score += 20 if exp[:website].present?
        score += 15 if exp[:phone].present?
        score += 10 if exp[:cultural_explanation].present? && exp[:cultural_explanation].length > 50
        score += 5 if exp[:qloo_keywords]&.any?
        score
      end
      
      (quality_scores.sum.to_f / experiences.size).round(1)
    end

    def calculate_keyword_density(experiences)
      total_keywords = experiences.sum { |exp| exp[:qloo_keywords]&.size || 0 }
      return 0 if experiences.empty?
      
      (total_keywords.to_f / experiences.size).round(1)
    end

    # Storage methods
    def store_journey_metrics(metrics)
      # In a real implementation, this would store to a time-series database
      # like InfluxDB, or a analytics service like Mixpanel
      Rails.cache.write("journey_metrics:#{metrics[:process_id]}", metrics, expires_in: 7.days)
      
      # Also append to daily aggregation
      daily_key = "daily_journeys:#{Date.current.strftime('%Y-%m-%d')}"
      daily_metrics = Rails.cache.read(daily_key) || []
      daily_metrics << metrics
      Rails.cache.write(daily_key, daily_metrics, expires_in: 30.days)
    end

    def store_llm_metrics(metrics)
      # Store LLM performance metrics
      llm_key = "llm_metrics:#{Time.current.strftime('%Y-%m-%d-%H')}"
      hourly_metrics = Rails.cache.read(llm_key) || []
      hourly_metrics << metrics
      Rails.cache.write(llm_key, hourly_metrics, expires_in: 7.days)
    end

    def store_curation_metrics(metrics)
      # Store curation effectiveness metrics
      curation_key = "curation_metrics:#{Date.current.strftime('%Y-%m-%d')}"
      daily_curation = Rails.cache.read(curation_key) || []
      daily_curation << metrics
      Rails.cache.write(curation_key, daily_curation, expires_in: 30.days)
    end

    def store_error_metrics(error_data)
      # Store error metrics for monitoring
      error_key = "error_metrics:#{Date.current.strftime('%Y-%m-%d')}"
      daily_errors = Rails.cache.read(error_key) || []
      daily_errors << error_data
      Rails.cache.write(error_key, daily_errors, expires_in: 30.days)
    end

    # Statistics update methods
    def update_language_usage_stats(language)
      return unless language
      
      stats_key = "language_usage:#{Date.current.strftime('%Y-%m-%d')}"
      daily_stats = Rails.cache.read(stats_key) || {}
      daily_stats[language] = (daily_stats[language] || 0) + 1
      Rails.cache.write(stats_key, daily_stats, expires_in: 30.days)
    end

    def update_city_popularity_stats(city)
      return unless city
      
      stats_key = "city_popularity:#{Date.current.strftime('%Y-%m-%d')}"
      daily_stats = Rails.cache.read(stats_key) || {}
      daily_stats[city] = (daily_stats[city] || 0) + 1
      Rails.cache.write(stats_key, daily_stats, expires_in: 30.days)
    end

    def update_llm_performance_stats(operation, duration, success)
      stats_key = "llm_performance:#{operation}:#{Date.current.strftime('%Y-%m-%d')}"
      daily_stats = Rails.cache.read(stats_key) || { total: 0, success: 0, total_duration: 0.0 }
      
      daily_stats[:total] += 1
      daily_stats[:success] += 1 if success
      daily_stats[:total_duration] += duration
      
      Rails.cache.write(stats_key, daily_stats, expires_in: 7.days)
    end

    # Dashboard builders
    def build_performance_dashboard(timeframe)
      {
        total_journeys: get_total_journeys(timeframe),
        average_processing_time: get_average_processing_time(timeframe),
        success_rate: get_success_rate(timeframe),
        language_distribution: get_language_distribution(timeframe),
        top_cities: get_top_cities(timeframe, 5),
        data_quality_trend: get_data_quality_trend(timeframe),
        error_rate: get_error_rate(timeframe),
        llm_performance: get_llm_performance_summary(timeframe)
      }
    end

    def build_language_stats(timeframe)
      language_data = get_language_usage_data(timeframe)
      
      {
        total_requests: language_data.values.sum,
        languages: language_data.map do |lang, count|
          {
            language: lang,
            name: LocalizationService::LANGUAGE_CONFIG.dig(lang, 'name') || lang,
            count: count,
            percentage: (count.to_f / language_data.values.sum * 100).round(1)
          }
        end.sort_by { |item| -item[:count] }
      }
    end

    def build_city_rankings(timeframe, limit)
      city_data = get_city_usage_data(timeframe)
      
      city_data.map do |city, count|
        {
          city: city,
          requests: count,
          trending: calculate_city_trending_score(city, timeframe)
        }
      end.sort_by { |item| -item[:requests] }.first(limit)
    end

    # Health check methods
    def check_localization_service_health
      begin
        # Test basic functionality
        test_result = LocalizationService.detect_language("Hello world")
        {
          status: test_result.present? ? 'healthy' : 'degraded',
          response_time: measure_response_time { LocalizationService.adventure_title("Test", "en") },
          supported_languages: LocalizationService::SUPPORTED_LANGUAGES.size
        }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def check_llm_service_health
      begin
        # Test LLM connectivity without actual API call
        {
          status: ENV['OPENAI_API_KEY'].present? ? 'healthy' : 'misconfigured',
          cache_hit_rate: calculate_llm_cache_hit_rate,
          average_response_time: get_average_llm_response_time
        }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def check_curation_service_health
      begin
        # Test basic functionality
        test_vibe = { city: 'Test', interests: ['test'], detected_language: 'en' }
        test_result = CulturalCurationService.calculate_vibe_match({}, test_vibe, [])
        
        {
          status: test_result.is_a?(Numeric) ? 'healthy' : 'degraded',
          response_time: measure_response_time { CulturalCurationService.extract_enhanced_qloo_data({}) }
        }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def check_places_service_health
      begin
        {
          status: 'healthy',
          cache_hit_rate: calculate_places_cache_hit_rate,
          google_api_status: check_google_api_availability
        }
      rescue => e
        { status: 'unhealthy', error: e.message }
      end
    end

    def calculate_overall_health_status
      health_checks = [
        check_localization_service_health[:status],
        check_llm_service_health[:status],
        check_curation_service_health[:status],
        check_places_service_health[:status]
      ]
      
      if health_checks.all? { |status| status == 'healthy' }
        'healthy'
      elsif health_checks.any? { |status| status == 'unhealthy' }
        'unhealthy'
      else
        'degraded'
      end
    end

    # Utility methods
    def measure_response_time
      start_time = Time.current
      yield
      (Time.current - start_time) * 1000 # Convert to milliseconds
    rescue
      nil
    end

    def determine_error_severity(error)
      case error
      when JSON::ParserError, ArgumentError then 'medium'
      when NoMethodError, NameError then 'critical'
      when StandardError then 'medium'  # Cambiado de 'high' a 'medium'
      else 'low'
      end
    end

    def alert_if_critical_error(error_data)
      if error_data[:severity] == 'critical'
        # In a real implementation, this would send alerts via Slack, email, etc.
        Rails.logger.error "🚨 CRITICAL ERROR: #{error_data[:error_message]}"
      end
    end

    # Placeholder methods for data retrieval
    # In a real implementation, these would query your analytics database
    
    def get_total_journeys(timeframe)
      # Mock implementation
      case timeframe
      when '24h' then 150
      when '7d' then 980
      when '30d' then 4200
      else 0
      end
    end

    def get_average_processing_time(timeframe)
      # Mock implementation - returns average in seconds
      2.3
    end

    def get_success_rate(timeframe)
      # Mock implementation - returns percentage
      94.7
    end

    def get_language_distribution(timeframe)
      # Mock implementation
      { 'es' => 45, 'en' => 35, 'fr' => 12, 'pt' => 5, 'it' => 2, 'de' => 1 }
    end

    def get_top_cities(timeframe, limit)
      # Mock implementation
      [
        { city: 'Mexico City', count: 120 },
        { city: 'Madrid', count: 85 },
        { city: 'Barcelona', count: 65 },
        { city: 'Paris', count: 45 },
        { city: 'Rome', count: 30 }
      ].first(limit)
    end

    def get_data_quality_trend(timeframe)
      # Mock implementation - returns array of daily quality scores
      [78.5, 82.1, 85.3, 87.2, 89.1]
    end

    def get_error_rate(timeframe)
      # Mock implementation - returns error percentage
      2.3
    end

    def get_llm_performance_summary(timeframe)
      # Mock implementation
      {
        average_response_time: 850, # milliseconds
        success_rate: 98.5,
        cache_hit_rate: 35.2
      }
    end

    def get_language_usage_data(timeframe)
      # Mock implementation
      { 'es' => 450, 'en' => 320, 'fr' => 180, 'pt' => 90, 'it' => 45, 'de' => 25 }
    end

    def get_city_usage_data(timeframe)
      # Mock implementation
      { 'Mexico City' => 340, 'Madrid' => 250, 'Barcelona' => 180, 'Paris' => 120, 'Rome' => 85 }
    end

    def calculate_city_trending_score(city, timeframe)
      # Mock implementation - returns trending score
      rand(0.8..1.5).round(2)
    end

    def calculate_llm_cache_hit_rate
      # Mock implementation
      32.5
    end

    def get_average_llm_response_time
      # Mock implementation
      750 # milliseconds
    end

    def calculate_places_cache_hit_rate
      # Mock implementation
      45.8
    end

    def check_google_api_availability
      # Mock implementation
      'available'
    end

    # Report builders (simplified)
    def build_summary_metrics(start_date, end_date)
      { total_journeys: 1250, success_rate: 94.7, average_quality: 86.3 }
    end

    def build_language_analysis(start_date, end_date)
      { dominant_language: 'es', growth_rate: 12.5, new_languages: ['ja'] }
    end

    def build_performance_analysis(start_date, end_date)
      { avg_processing_time: 2.1, peak_load_time: '14:00-16:00', bottlenecks: ['llm_calls'] }
    end

    def build_quality_analysis(start_date, end_date)
      { avg_data_quality: 87.2, qloo_coverage: 78.5, coordinate_accuracy: 94.1 }
    end

    def build_user_behavior_analysis(start_date, end_date)
      { popular_interests: ['restaurant', 'museum', 'bar'], peak_usage: 'weekends' }
    end

    def generate_optimization_recommendations(start_date, end_date)
      [
        'Increase LLM cache TTL to improve response times',
        'Add more Qloo API endpoints for better coverage',
        'Implement predictive caching for popular cities'
      ]
    end
  end
end