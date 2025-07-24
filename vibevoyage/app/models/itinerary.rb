class Itinerary < ApplicationRecord
  has_many :itinerary_stops, dependent: :destroy
  belongs_to :user, optional: true
  
  validates :description, presence: true
end
