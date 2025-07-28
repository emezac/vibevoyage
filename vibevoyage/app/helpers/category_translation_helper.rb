# app/helpers/category_translation_helper.rb
module CategoryTranslationHelper
  class << self
    def translate_google_place_type(type, language = 'en')
      translations = {
        'en' => {
          'lodging' => 'Hotel',
          'point_of_interest' => 'Attraction',
          'establishment' => 'Business',
          'restaurant' => 'Restaurant',
          'bar' => 'Bar',
          'cafe' => 'Café',
          'museum' => 'Museum',
          'art_gallery' => 'Art Gallery',
          'park' => 'Park',
          'store' => 'Shop',
          'tourist_attraction' => 'Tourist Spot',
          'night_club' => 'Nightclub',
          'movie_theater' => 'Cinema',
          'library' => 'Library',
          'bookstore' => 'Bookstore'
        },
        'fr' => {
          'lodging' => 'Hôtel',
          'point_of_interest' => 'Attraction',
          'establishment' => 'Établissement',
          'restaurant' => 'Restaurant',
          'bar' => 'Bar',
          'cafe' => 'Café',
          'museum' => 'Musée',
          'art_gallery' => 'Galerie d\'Art',
          'park' => 'Parc',
          'store' => 'Magasin',
          'tourist_attraction' => 'Attraction Touristique',
          'night_club' => 'Boîte de Nuit',
          'movie_theater' => 'Cinéma',
          'library' => 'Bibliothèque',
          'bookstore' => 'Librairie'
        },
        'es' => {
          'lodging' => 'Hotel',
          'point_of_interest' => 'Atracción',
          'establishment' => 'Establecimiento',
          'restaurant' => 'Restaurante',
          'bar' => 'Bar',
          'cafe' => 'Café',
          'museum' => 'Museo',
          'art_gallery' => 'Galería de Arte',
          'park' => 'Parque',
          'store' => 'Tienda',
          'tourist_attraction' => 'Atracción Turística',
          'night_club' => 'Discoteca',
          'movie_theater' => 'Cine',
          'library' => 'Biblioteca',
          'bookstore' => 'Librería'
        }
      }

      translation_map = translations[language] || translations['en']
      translation_map[type.to_s] || type.to_s.humanize
    end

    def translate_categories(categories, language = 'en')
      return [] unless categories.is_a?(Array)
      
      # Priority mapping to show most relevant categories first
      priority_types = ['restaurant', 'bar', 'cafe', 'museum', 'art_gallery', 'tourist_attraction', 'park', 'store', 'lodging']
      
      # Filter out generic types and prioritize meaningful ones
      filtered_categories = categories.reject { |cat| ['establishment', 'point_of_interest'].include?(cat) }
      
      # If no meaningful categories left, keep the most relevant generic one
      if filtered_categories.empty?
        filtered_categories = categories.include?('point_of_interest') ? ['point_of_interest'] : [categories.first].compact
      end

      # Sort by priority, then translate
      sorted_categories = filtered_categories.sort_by do |category|
        index = priority_types.index(category)
        index ? index : 999
      end

      # Translate and limit to 3 most relevant
      sorted_categories.first(3).map { |cat| translate_google_place_type(cat, language) }
    end

    def get_category_icon(type)
      icons = {
        'restaurant' => '🍽️',
        'bar' => '🍸',
        'cafe' => '☕',
        'museum' => '🏛️',
        'art_gallery' => '🎨',
        'park' => '🌳',
        'store' => '🛍️',
        'lodging' => '🏨',
        'tourist_attraction' => '📍',
        'night_club' => '🌃',
        'movie_theater' => '🎬',
        'library' => '📚',
        'bookstore' => '📖',
        'point_of_interest' => '📍',
        'establishment' => '🏢'
      }

      icons[type] || '📍'
    end
  end
end
