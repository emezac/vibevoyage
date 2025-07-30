# app/models/itinerary.rb
class Itinerary < ApplicationRecord
  belongs_to :user
  has_many :itinerary_stops, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_slug, if: :new_record?
  before_validation :generate_meta_data, if: -> { is_public? && meta_title.blank? }

  scope :public_itineraries, -> { where(is_public: true) }
  scope :popular, -> { order(view_count: :desc) }
  scope :recent_shared, -> { where.not(shared_at: nil).order(shared_at: :desc) }
  scope :recent_made_public, -> { where.not(made_public_at: nil).order(made_public_at: :desc) }

  def to_param
    slug.presence || id.to_s
  end

  def share_url
    Rails.application.routes.url_helpers.shared_itinerary_url(self)
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def increment_share_count!
    increment!(:share_count)
    update!(shared_at: Time.current) if shared_at.nil?
  end

  def make_public!
    update!(
      is_public: true,
      shared_at: Time.current,
      made_public_at: Time.current  # ✅ Agregar esta línea
    )
    generate_meta_data
    save!
  end

  def shareable_title
    meta_title.presence || "#{user.display_name}'s Cultural Journey in #{city}"
  end

  def shareable_description
    meta_description.presence || "Discover #{description} - A curated cultural adventure through #{city}."
  end

  private

  def generate_slug
    base_slug = generate_base_slug
    counter = 1
    potential_slug = base_slug

    while Itinerary.exists?(slug: potential_slug)
      potential_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = potential_slug
  end

  def generate_base_slug
    if name.present?
      name.parameterize
    elsif city.present? && user.present?
      "#{user.first_name&.parameterize || 'adventure'}-in-#{city.parameterize}"
    else
      "cultural-journey-#{SecureRandom.hex(4)}"
    end
  end

  def generate_meta_data
    return unless is_public?

    self.meta_title = generate_meta_title
    self.meta_description = generate_meta_description
  end

  def generate_meta_title
    if city.present?
      "#{user.display_name}'s #{extract_vibe_keywords} Adventure in #{city}"
    else
      "#{user.display_name}'s Cultural Journey"
    end
  end

  def generate_meta_description
    stops_preview = itinerary_stops.limit(3).pluck(:name).join(", ")
    base_desc = "Experience #{description}"
    
    if stops_preview.present?
      "#{base_desc} featuring #{stops_preview} and more cultural gems."
    else
      "#{base_desc} - A curated cultural adventure."
    end
  end

  def extract_vibe_keywords
    # Extract keywords from description for more engaging titles
    keywords = description&.scan(/\b(bohemian|vintage|modern|artistic|culinary|historic|trendy|local|authentic)\b/i)&.flatten&.first
    keywords&.capitalize || "Cultural"
  end
end