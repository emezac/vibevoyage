
require 'rails_helper'

RSpec.describe "ItineraryStops", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:itinerary) { FactoryBot.create(:itinerary, user: user) }
  let!(:itinerary_stop) { FactoryBot.create(:itinerary_stop, itinerary: itinerary) }

  describe "GET /itineraries/:itinerary_id/itinerary_stops" do
    it "returns http success" do
      get itinerary_itinerary_stops_path(itinerary)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /itineraries/:itinerary_id/itinerary_stops/:id" do
    it "returns http success" do
      get itinerary_itinerary_stop_path(itinerary, itinerary_stop)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /itineraries/:itinerary_id/itinerary_stops" do
    it "creates a new stop" do
      post itinerary_itinerary_stops_path(itinerary), params: { itinerary_stop: { name: "Nueva parada", description: "Test", latitude: 0.0, longitude: 0.0 } }
      expect(response).to have_http_status(:redirect).or have_http_status(:success)
    end
  end

  describe "PATCH /itineraries/:itinerary_id/itinerary_stops/:id" do
    it "updates a stop" do
      patch itinerary_itinerary_stop_path(itinerary, itinerary_stop), params: { itinerary_stop: { name: "Actualizado" } }
      expect(response).to have_http_status(:redirect).or have_http_status(:success)
    end
  end

  describe "DELETE /itineraries/:itinerary_id/itinerary_stops/:id" do
    it "deletes a stop" do
      delete itinerary_itinerary_stop_path(itinerary, itinerary_stop)
      expect(response).to have_http_status(:redirect).or have_http_status(:success)
    end
  end
end
