# db/migrate/xxx_add_shareable_fields_to_itineraries.rb
class AddShareableFieldsToItineraries < ActiveRecord::Migration[8.0]
  def change
    add_column :itineraries, :slug, :string
    add_column :itineraries, :is_public, :boolean, default: false
    add_column :itineraries, :meta_title, :string
    add_column :itineraries, :meta_description, :text
    add_column :itineraries, :og_image_url, :string
    add_column :itineraries, :shared_at, :datetime
    add_column :itineraries, :view_count, :integer, default: 0
    add_column :itineraries, :share_count, :integer, default: 0
    
    add_index :itineraries, :slug, unique: true
    add_index :itineraries, :is_public
    add_index :itineraries, :shared_at
  end
end
