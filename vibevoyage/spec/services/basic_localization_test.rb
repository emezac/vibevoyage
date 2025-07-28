# spec/services/basic_localization_test.rb
# Test básico que se ejecuta independientemente de Rails

require 'json'
require 'digest'
require 'securerandom'
require 'cgi'

# Mock básico de Rails.cache
module Rails
  class << self
    def cache
      @cache ||= MockCache.new
    end

    def logger
      @logger ||= MockLogger.new
    end
    
    def root
      Pathname.new(Dir.pwd)
    end
    
    def env
      @env ||= MockEnv.new
    end
  end

  class MockCache
    def initialize
      @store = {}
    end

    def fetch(key, options = {})
      if @store.key?(key)
        @store[key]
      else
        value = yield if block_given?
        @store[key] = value
        value
      end
    end

    def write(key, value, options = {})
      @store[key] = value
    end

    def read(key)
      @store[key]
    end

    def clear
      @store.clear
    end
  end

  class MockLogger
    def info(message)
      puts "[INFO] #{message}"
    end

    def error(message)
      puts "[ERROR] #{message}"
    end

    def warn(message)
      puts "[WARN] #{message}"
    end
  end
  
  class MockEnv
    def development?
      true
    end
    
    def test?
      true
    end
    
    def production?
      false
    end
  end
end

# Mock básico de Pathname si no está disponible
unless defined?(Pathname)
  class Pathname
    def initialize(path)
      @path = path.to_s
    end
    
    def to_s
      @path
    end
  end
end

# Agregar métodos de ActiveSupport básicos a String
class String
  def blank?
    self.nil? || self.strip.empty?
  end
  
  def present?
    !blank?
  end
end

# Agregar métodos a NilClass
class NilClass
  def blank?
    true
  end
  
  def present?
    false
  end
end

# Mock para LLMService si no está disponible
unless defined?(LLMService)
  module LLMService
    def self.detect_language(text)
      # Simple mock para testing
      return 'es' if text.downcase.include?('méxico') || text.downcase.include?('ciudad')
      return 'fr' if text.downcase.include?('paris') || text.downcase.include?('avec')
      'en'
    end
  end
end

# Cargar el servicio directamente
service_path = File.expand_path('../../app/services/localization_service.rb', __dir__)
if File.exist?(service_path)
  load service_path
else
  puts "❌ LocalizationService not found at #{service_path}"
  puts "Please make sure the service file exists."
  exit 1
end

# Tests básicos
def test_language_detection
  puts "\n🧪 Testing Language Detection..."
  
  # Test Spanish detection
  spanish_text = "Una tarde contemplativa en Ciudad de México"
  detected = LocalizationService.detect_language(spanish_text)
  puts "   Spanish text: '#{spanish_text}' -> '#{detected}'"
  if detected == 'es'
    puts "✅ Spanish detection: PASSED"
  else
    puts "❌ Spanish detection: FAILED (got #{detected})"
  end
  
  # Test English detection  
  english_text = "A cultural evening in New York"
  detected = LocalizationService.detect_language(english_text)
  puts "   English text: '#{english_text}' -> '#{detected}'"
  if detected == 'en'
    puts "✅ English detection: PASSED"
  else
    puts "❌ English detection: FAILED (got #{detected})"
  end
  
  # Test with common English words
  english_text2 = "This is a wonderful place"
  detected2 = LocalizationService.detect_language(english_text2)
  puts "   English text 2: '#{english_text2}' -> '#{detected2}'"
  if detected2 == 'en'
    puts "✅ English detection 2: PASSED"
  else
    puts "❌ English detection 2: FAILED (got #{detected2})"
  end
  
  # Test empty text
  detected = LocalizationService.detect_language("")
  if detected == 'en'
    puts "✅ Empty text fallback: PASSED"
  else
    puts "❌ Empty text fallback: FAILED (got #{detected})"
  end
end

def test_localization
  puts "\n🌍 Testing Localization..."
  
  # Debug: let's check what the config looks like
  puts "   Debug: Testing basic localize method..."
  result = LocalizationService.localize('narrative_labels.adventure_title', 'es')
  puts "   localize('narrative_labels.adventure_title', 'es') = '#{result}'"
  
  # Test adventure title generation
  title_es = LocalizationService.adventure_title("Madrid", "es")
  expected_es = "Tu Aventura Cultural en Madrid"
  puts "   Spanish title: '#{title_es}' vs expected '#{expected_es}'"
  if title_es == expected_es
    puts "✅ Spanish title: PASSED"
  else
    puts "❌ Spanish title: FAILED (got '#{title_es}', expected '#{expected_es}')"
  end
  
  title_en = LocalizationService.adventure_title("Paris", "en")
  expected_en = "Your Cultural Adventure in Paris"
  puts "   English title: '#{title_en}' vs expected '#{expected_en}'"
  if title_en == expected_en
    puts "✅ English title: PASSED"
  else
    puts "❌ English title: FAILED (got '#{title_en}', expected '#{expected_en}')"
  end
  
  # Test basic localization
  result = LocalizationService.localize('narrative_labels.adventure_title', 'fr')
  expected = 'Votre Aventure Culturelle à'
  puts "   French localization: '#{result}' vs expected '#{expected}'"
  if result == expected
    puts "✅ French localization: PASSED"
  else
    puts "❌ French localization: FAILED (got '#{result}', expected '#{expected}')"
  end
end

def test_fallback_experiences
  puts "\n🎭 Testing Fallback Experiences..."
  
  experiences = LocalizationService.generate_fallback_experiences("Barcelona", ["art", "food"], "es")
  
  puts "   Generated #{experiences.size} experiences"
  if experiences.size == 3
    puts "✅ Experience count: PASSED"
  else
    puts "❌ Experience count: FAILED (got #{experiences.size}, expected 3)"
  end
  
  first_exp = experiences.first
  required_fields = [:time, :title, :location, :description, :cultural_explanation]
  
  missing_fields = required_fields.select { |field| !first_exp.key?(field) }
  if missing_fields.empty?
    puts "✅ Required fields: PASSED"
  else
    puts "❌ Required fields: FAILED (missing: #{missing_fields})"
  end
  
  puts "   First experience title: '#{first_exp[:title]}'"
  if first_exp[:title].include?("Mañana:")
    puts "✅ Spanish localization: PASSED"
  else
    puts "❌ Spanish localization: FAILED (title: #{first_exp[:title]})"
  end
end

def test_narrative_generation
  puts "\n📖 Testing Narrative Generation..."
  
  html = LocalizationService.build_narrative_html(
    "Test vibe", 
    "Madrid", 
    ["art", "culture"], 
    3, 
    "es"
  )
  
  if html.include?('<div class="narrative')
    puts "✅ HTML structure: PASSED"
  else
    puts "❌ HTML structure: FAILED"
  end
  
  adventure_title = "Tu Aventura Cultural en Madrid"
  puts "   Looking for: '#{adventure_title}'"
  if html.include?(adventure_title)
    puts "✅ Spanish narrative: PASSED"
  else
    puts "❌ Spanish narrative: FAILED"
    # Debug: show first 200 characters of HTML
    puts "   HTML preview: #{html[0..200]}..."
  end
  
  if html.include?("Test vibe")
    puts "✅ User vibe inclusion: PASSED"
  else
    puts "❌ User vibe inclusion: FAILED"
  end
end

def test_supported_languages
  puts "\n🔤 Testing Language Support..."
  
  supported = %w[es en fr pt it de]
  supported.each do |lang|
    if LocalizationService.supported_language?(lang)
      puts "✅ #{lang.upcase} support: PASSED"
    else
      puts "❌ #{lang.upcase} support: FAILED"
    end
  end
  
  if !LocalizationService.supported_language?('xx')
    puts "✅ Invalid language rejection: PASSED"
  else
    puts "❌ Invalid language rejection: FAILED"
  end
end

def test_experience_title_generation
  puts "\n📝 Testing Experience Title Generation..."
  
  # Test morning discovery in Spanish
  title = LocalizationService.experience_title(:morning, :discovery, 'es')
  expected = "Mañana: Descubrimiento Cultural"
  puts "   Spanish morning title: '#{title}' vs expected '#{expected}'"
  if title == expected
    puts "✅ Spanish experience title: PASSED"
  else
    puts "❌ Spanish experience title: FAILED"
  end
  
  # Test afternoon immersion in English
  title_en = LocalizationService.experience_title(:afternoon, :immersion, 'en')
  expected_en = "Afternoon: Authentic Immersion"
  puts "   English afternoon title: '#{title_en}' vs expected '#{expected_en}'"
  if title_en == expected_en
    puts "✅ English experience title: PASSED"
  else
    puts "❌ English experience title: FAILED"
  end
end

def run_all_tests
  puts "🚀 Running Basic LocalizationService Tests"
  puts "=" * 50
  
  test_supported_languages
  test_language_detection
  test_localization
  test_experience_title_generation
  test_fallback_experiences
  test_narrative_generation
  
  puts "\n" + "=" * 50
  puts "✨ Tests completed!"
  puts "\nTo run the full test suite:"
  puts "bundle exec rspec spec/services/localization_service_spec.rb"
end

# Ejecutar tests si este archivo se ejecuta directamente
if __FILE__ == $0
  run_all_tests
end