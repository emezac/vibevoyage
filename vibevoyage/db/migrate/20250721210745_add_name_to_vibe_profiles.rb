class AddNameToVibeProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :vibe_profiles, :name, :string
  end
end
