class AddPositionToItineraryStops < ActiveRecord::Migration[8.0]
  def change
    add_column :itinerary_stops, :position, :integer
    add_index :itinerary_stops, :position
  end
end
