# config/initializers/services.rb


Rails.application.config.to_prepare do
  begin
    if defined?(LocalizationService)
      LocalizationService::SUPPORTED_LANGUAGES.each do |lang|
        LocalizationService.send(:language_config, lang)
      end
    end

    # Initialize analytics
    if defined?(AnalyticsService)
      AnalyticsService.get_service_health
    end
    
    Rails.logger.info "🚀 Cultural Services (re)initialized successfully"
    
  rescue => e
    Rails.logger.error "💥 FAILED to initialize cultural services: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end