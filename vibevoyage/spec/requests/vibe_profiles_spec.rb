
require 'rails_helper'

RSpec.describe "VibeProfiles", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:vibe_profile) { FactoryBot.create(:vibe_profile, user: user) }

  describe "GET /vibe_profiles" do
    it "returns http success" do
      get vibe_profiles_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /vibe_profiles/:id" do
    it "returns http success" do
      get vibe_profile_path(vibe_profile)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /vibe_profiles" do
    it "creates a new vibe_profile" do
      post vibe_profiles_path, params: { vibe_profile: { name: "Perfil Test", description: "Test", user_id: user.id } }
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /vibe_profiles/:id" do
    it "updates a vibe_profile" do
      patch vibe_profile_path(vibe_profile), params: { vibe_profile: { name: "Actualizado" } }
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /vibe_profiles/:id" do
    it "deletes a vibe_profile" do
      delete vibe_profile_path(vibe_profile)
      expect(response).to have_http_status(:no_content)
    end
  end
end
