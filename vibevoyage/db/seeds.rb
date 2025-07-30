# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# db/seeds.rb

# Crear planes de subscripción
puts "🌱 Creating subscription plans..."

# Plan Gratis
free_plan = SubscriptionPlan.find_or_create_by(slug: 'free') do |plan|
  plan.name = 'Free Explorer'
  plan.price = 0.0
  plan.description = 'Perfect for trying out VibeVoyage'
  plan.features = [
    '1 cultural journey per month',
    'Basic AI curation',
    'Standard recommendations',
    'Community support'
  ]
  plan.max_journeys_per_month = 1
  plan.active = true
end

# Plan Premium
premium_plan = SubscriptionPlan.find_or_create_by(slug: 'premium') do |plan|
  plan.name = 'Cultural Connoisseur'
  plan.price = 19.99
  plan.description = 'For the true cultural explorer'
  plan.features = [
    'Unlimited cultural journeys',
    'Advanced AI with Qloo intelligence',
    'Premium recommendations',
    'Cultural DNA analysis',
    'Detailed cultural insights',
    'Priority support'
  ]
  plan.max_journeys_per_month = 999
  plan.active = true
end

# Plan Enterprise
enterprise_plan = SubscriptionPlan.find_or_create_by(slug: 'enterprise') do |plan|
  plan.name = 'Cultural Architect'
  plan.price = 49.99
  plan.description = 'For cultural institutions and power users'
  plan.features = [
    'Everything in Premium',
    'Advanced cultural insights',
    'Custom cultural narratives',
    'API access (coming soon)',
    'White-label options (coming soon)',
    'Dedicated account manager',
    'Custom integrations'
  ]
  plan.max_journeys_per_month = 999
  plan.active = true
end

puts "✅ Created subscription plans:"
puts "   - #{free_plan.name} ($#{free_plan.price})"
puts "   - #{premium_plan.name} ($#{premium_plan.price})"
puts "   - #{enterprise_plan.name} ($#{enterprise_plan.price})"

# Crear usuario administrador
admin_email = ENV['ADMIN_EMAIL'] || 'admin@vibevoyage.com'
admin_password = ENV['ADMIN_PASSWORD'] || 'VibeVoyage2025!'

admin_user = User.find_or_create_by(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
  user.first_name = 'Admin'
  user.last_name = 'VibeVoyage'
  user.subscription_plan = premium_plan
  user.subscription_status = 'active'
  user.subscription_expires_at = 1.year.from_now
end

puts "👨‍💼 Created admin user: #{admin_user.email}"

# Actualizar usuarios existentes sin plan
User.where(subscription_plan: nil).update_all(subscription_plan_id: free_plan.id)
puts "🔧 Updated existing users to free plan"

puts "🎉 Database seeded successfully!"
