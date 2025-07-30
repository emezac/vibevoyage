class AddSubscriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :subscription_plan, null: true, foreign_key: true
    add_column :users, :subscription_status, :string, default: 'free'
    add_column :users, :subscription_expires_at, :datetime
    add_column :users, :journeys_this_month, :integer, default: 0
    add_column :users, :last_journey_reset, :date
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    
    add_index :users, :subscription_status
    add_index :users, :subscription_expires_at
  end
end
