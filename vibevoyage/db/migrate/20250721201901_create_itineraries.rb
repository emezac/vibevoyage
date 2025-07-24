class CreateItineraries < ActiveRecord::Migration[8.0]
  def change
    create_table :itineraries do |t|
      t.string :name
      t.string :location
      t.jsonb :themes
      t.text :narrative_html
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
