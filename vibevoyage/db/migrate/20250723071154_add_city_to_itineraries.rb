class AddCityToItineraries < ActiveRecord::Migration[8.0]
  def change
    add_column :itineraries, :city, :string
  end
end
