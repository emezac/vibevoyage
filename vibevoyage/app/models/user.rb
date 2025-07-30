# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :subscription_plan, optional: true
  has_many :itineraries, dependent: :destroy
  has_many :vibe_profiles, dependent: :destroy

  enum :subscription_status, { free: 0, active: 1, expired: 2, canceled: 3 }

  before_create :set_default_subscription
  before_save :reset_monthly_journeys_if_needed

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.present? ? full_name : email.split('@').first.humanize
  end

  def can_create_journey?
    return true if admin? || subscription_status == 'active'
    
    # Free plan: 1 journey per month
    current_plan = subscription_plan || SubscriptionPlan.free_plan
    journeys_this_month < current_plan.max_journeys_per_month
  end

  def journeys_remaining_this_month
    current_plan = subscription_plan || SubscriptionPlan.free_plan
    [current_plan.max_journeys_per_month - journeys_this_month, 0].max
  end

  def subscription_active?
    subscription_status == 'active' && 
    subscription_expires_at && 
    subscription_expires_at > Time.current
  end

  def subscription_expired?
    subscription_expires_at && subscription_expires_at <= Time.current
  end

  def increment_journey_count!
    reset_monthly_journeys_if_needed
    increment!(:journeys_this_month)
  end

  def admin?
    # Define admin logic here (could be a role column)
    email.in?(['admin@vibevoyage.com', 'tu-email@example.com'])
  end

  private

  def set_default_subscription
    self.subscription_plan ||= SubscriptionPlan.free_plan
    self.subscription_status ||= 'free'
    self.journeys_this_month ||= 0
    self.last_journey_reset ||= Date.current
  end

  def reset_monthly_journeys_if_needed
    if last_journey_reset.nil? || last_journey_reset < Date.current.beginning_of_month
      self.journeys_this_month = 0
      self.last_journey_reset = Date.current
    end
  end
end
