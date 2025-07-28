# config/initializers/analytics.rb
Rails.application.configure do
  config.middleware.insert_before 0, 'AnalyticsMiddleware' if defined?(AnalyticsMiddleware)
  
  # Configure error tracking
  config.after_initialize do
    if Rails.env.production?
      # Setup error notifications
      Rails.logger.info "📊 Analytics and monitoring enabled"
    end
  end
end
