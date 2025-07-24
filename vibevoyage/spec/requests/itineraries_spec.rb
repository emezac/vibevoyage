
require 'rails_helper'

RSpec.describe "Itineraries", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:itinerary) { FactoryBot.create(:itinerary, user: user) }

  describe "GET /itineraries" do
    it "returns http success" do
      get itineraries_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /itineraries/:id" do
    it "returns http success" do
      get itinerary_path(itinerary)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /itineraries" do
    it "encola el VibeCurationJob y responde con turbo-stream" do
      ActiveJob::Base.queue_adapter = :test
      sign_in user
      expect {
        post itineraries_path, params: { itinerary: { name: "Viaje Test", location: "Madrid", themes: ["arte"] } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      }.to have_enqueued_job(VibeCurationJob)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("turbo-stream")
    end
  end

  describe "PATCH /itineraries/:id" do
    it "updates an itinerary" do
      patch itinerary_path(itinerary), params: { itinerary: { name: "Actualizado" } }
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /itineraries/:id" do
    it "deletes an itinerary" do
      delete itinerary_path(itinerary)
      expect(response).to have_http_status(:no_content)
    end
  end
end
