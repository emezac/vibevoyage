# db/migrate/xxx_create_subscription_plans.rb
class CreateSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.text :description
      t.json :features, default: []
      t.integer :max_journeys_per_month, default: 1
      t.boolean :active, default: true
      t.timestamps
    end
    
    add_index :subscription_plans, :slug, unique: true
    add_index :subscription_plans, :active
  end
end
