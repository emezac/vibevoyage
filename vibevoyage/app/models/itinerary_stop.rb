class ItineraryStop < ApplicationRecord
  belongs_to :itinerary
  
  validates :name, presence: true
  validates :position, presence: true
end
