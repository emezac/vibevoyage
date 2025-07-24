class AddDescriptionToItineraries < ActiveRecord::Migration[8.0]
  def change
    add_column :itineraries, :description, :string
  end
end
