require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many(:itineraries) }
  it { should have_many(:vibe_profiles) }
end
