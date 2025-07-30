class AddMadePublicAtToItineraries < ActiveRecord::Migration[8.0]
  def change
    add_column :itineraries, :made_public_at, :datetime
    add_index :itineraries, :made_public_at
  end
end
