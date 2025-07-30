# app/models/subscription_plan.rb
class SubscriptionPlan < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_journeys_per_month, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :by_price, -> { order(:price) }

  def self.free_plan
    find_or_create_by(slug: 'free') do |plan|
      plan.name = 'Free Explorer'
      plan.price = 0.0
      plan.description = 'Perfect for trying out VibeVoyage'
      plan.features = [
        '3 cultural journeys per month',
        'Basic AI curation',
        'Standard recommendations'
      ]
      plan.max_journeys_per_month = 3
      plan.active = true
    end
  end

  def self.premium_plan
    find_or_create_by(slug: 'premium') do |plan|
      plan.name = 'Cultural Connoisseur'
      plan.price = 19.99
      plan.description = 'For the true cultural explorer'
      plan.features = [
        'Unlimited cultural journeys',
        'Advanced AI with Qloo intelligence',
        'Premium recommendations',
        'Cultural DNA analysis',
        'Priority support'
      ]
      plan.max_journeys_per_month = 999
      plan.active = true
    end
  end

  def self.enterprise_plan
    find_or_create_by(slug: 'enterprise') do |plan|
      plan.name = 'Cultural Architect'
      plan.price = 49.99
      plan.description = 'For cultural institutions and power users'
      plan.features = [
        'Everything in Premium',
        'Advanced cultural insights',
        'Custom cultural narratives',
        'API access',
        'White-label options',
        'Dedicated account manager'
      ]
      plan.max_journeys_per_month = 999
      plan.active = true
    end
  end

  def free?
    slug == 'free' || price == 0
  end

  def monthly_price
    price
  end

  def yearly_price
    price * 10 # 2 months free
  end
end
