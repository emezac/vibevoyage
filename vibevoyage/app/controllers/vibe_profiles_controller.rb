
class VibeProfilesController < ApplicationController
  before_action :set_vibe_profile, only: [:show, :update, :destroy]

  def index
    @vibe_profiles = VibeProfile.all
    render json: @vibe_profiles
  end

  def show
    render json: @vibe_profile
  end

  def create
    @vibe_profile = VibeProfile.new(vibe_profile_params)
    if @vibe_profile.save
      render json: @vibe_profile, status: :created
    else
      render json: @vibe_profile.errors, status: :unprocessable_entity
    end
  end

  def update
    if @vibe_profile.update(vibe_profile_params)
      render json: @vibe_profile
    else
      render json: @vibe_profile.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @vibe_profile.destroy
    head :no_content
  end

  private
    def set_vibe_profile
      @vibe_profile = VibeProfile.find(params[:id])
    end

    def vibe_profile_params
      params.require(:vibe_profile).permit(:name, :description, :user_id)
    end
end
