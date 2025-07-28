# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'factory_bot_rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
# Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods
  
  config.before(:each) do

    # Mock LLMService methods if the service is defined
    if defined?(LLMService)
      allow(LLMService).to receive(:execute_llm_task).and_return('mock response')
      allow(LLMService).to receive(:detect_language).and_return('en')
      allow(LLMService).to receive(:parse_vibe).and_return({ 
        city: 'Test City', 
        interests: ['test'], 
        detected_language: 'en' 
      })
      allow(LLMService).to receive(:generate_cultural_explanation).and_return('Test explanation')
      allow(LLMService).to receive(:find_best_place_match).and_return(nil)
      allow(LLMService).to receive(:extract_area_from_address).and_return('Center')
      allow(LLMService).to receive(:generate_fallback_coordinates).and_return({
        latitude: 40.7128,
        longitude: -74.0060,
        place_name: 'Test Place'
      })
    end
    
    # Mock RdawnApiService methods if defined
    if defined?(RdawnApiService)
      allow(RdawnApiService).to receive(:qloo_recommendations).and_return({ 
        success: true, 
        data: { 'results' => { 'entities' => [] } } 
      })
      allow(RdawnApiService).to receive(:google_places).and_return({ 
        success: true, 
        data: { 'results' => [] } 
      })
    end
    
    # Mock AnalyticsService if defined
    if defined?(AnalyticsService)
      allow(AnalyticsService).to receive(:track_journey_processing).and_return({})
      allow(AnalyticsService).to receive(:track_llm_performance).and_return({})
      allow(AnalyticsService).to receive(:track_curation_effectiveness).and_return({})
      allow(AnalyticsService).to receive(:track_error).and_return({})
    end
  end

  config.after(:each) do
    Rails.cache.clear
  end

  # config.use_active_record = false
  # config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  # config.filter_gems_from_backtrace("gem name")
end

# Shoulda Matchers config
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end