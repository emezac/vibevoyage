class AddQlooDataToItineraryStops < ActiveRecord::Migration[8.0]
  def change
    add_column :itinerary_stops, :qloo_data, :jsonb
  end
end
