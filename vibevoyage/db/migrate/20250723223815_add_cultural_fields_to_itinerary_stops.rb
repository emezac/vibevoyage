class AddCulturalFieldsToItineraryStops < ActiveRecord::Migration[8.0]
  def change
    add_column :itinerary_stops, :cultural_explanation, :text
    add_column :itinerary_stops, :why_chosen, :string
    add_column :itinerary_stops, :qloo_keywords, :string
  end
end
