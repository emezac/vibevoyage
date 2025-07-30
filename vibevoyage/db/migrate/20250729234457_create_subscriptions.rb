class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.decimal :price
      t.string :status
      t.text :features
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
