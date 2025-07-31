# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' },
    reconnect_attempts: 1,
    network_timeout: 5
  }

  Rails.logger.info("✅ Sidekiq server configurado con #{config.redis[:url]}")
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' },
    network_timeout: 5
  }
end

# Integrar ActiveJob con Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq

