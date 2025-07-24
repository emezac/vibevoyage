class AddDescriptionToVibeProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :vibe_profiles, :description, :string
  end
end
