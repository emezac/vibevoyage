require 'rails_helper'

RSpec.describe Itinerary, type: :model do
  it { should belong_to(:user) }
  it { should have_many(:itinerary_stops) }

  it 'is valid with valid attributes and user' do
    user = FactoryBot.create(:user)
    itinerary = FactoryBot.build(:itinerary, user: user)
    expect(itinerary).to be_valid
  end

  it 'is invalid without a name' do
    itinerary = FactoryBot.build(:itinerary, name: nil)
    expect(itinerary).not_to be_valid
  end
end
