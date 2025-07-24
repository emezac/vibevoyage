class CreateVibeProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :vibe_profiles do |t|
      t.string :category
      t.string :entity
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
