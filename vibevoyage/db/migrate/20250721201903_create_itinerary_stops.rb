class CreateItineraryStops < ActiveRecord::Migration[8.0]
  def change
    create_table :itinerary_stops do |t|
      t.string :name
      t.text :description
      t.string :address
      t.float :latitude
      t.float :longitude
      t.string :opening_hours
      t.references :itinerary, null: false, foreign_key: true

      t.timestamps
    end
  end
end
