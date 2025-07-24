

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { FactoryBot.create(:user) }

  describe "GET /users" do
    it "returns http success" do
      get users_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/:id" do
    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users (Web - HTML)" do
    it "creates a new user and redirects" do
      expect {
        post user_registration_path, params: {
          user: {
            email: "nuevo@ejemplo.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "POST /users (API - JSON)" do
    it "creates a new user and returns JSON with status 201" do
      expect {
        post user_registration_path,
          params: {
            user: {
              email: "nuevo@ejemplo.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }.to_json,
          headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['user']['email']).to eq('nuevo@ejemplo.com')
    end

    it "returns error for invalid user data" do
      post user_registration_path,
        params: {
          user: {
            email: "email_invalido",
            password: "123"
          }
        }.to_json,
        headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('error')
      expect(json_response['errors']).to be_present
    end
  end

  describe "PATCH /users/:id" do
    it "updates a user" do
      patch user_path(user), params: { user: { email: "actualizado@ejemplo.com" } }
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /users/:id" do
    it "deletes a user" do
      delete user_path(user)
      expect(response).to have_http_status(:no_content)
    end
  end
end
