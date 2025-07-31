# config/initializers/sidekiq.rb
redis_url = ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' }

Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    reconnect_attempts: 1,
    network_timeout: 5
  }
  Rails.logger.info("✅ Sidekiq server configurado con #{redis_url}")
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url,
    network_timeout: 5
  }
end

# Integrar ActiveJob con Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq
