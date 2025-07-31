# config/initializers/monitoring.rb
if Rails.env.production?
  # Configure Slack notifications
  Rails.application.config.after_initialize do
    AnalyticsService.class_eval do
      def self.alert_if_critical_error(error_data)
        if error_data[:severity] == 'critical'
          # SlackNotifier.new.ping("🚨 Critical Error: #{error_data[:error_message]}")
          Rails.logger.error "🚨 CRITICAL ERROR (SlackNotifier not configured): #{error_data[:error_message]}"
        end
      end
    end
  end
end
