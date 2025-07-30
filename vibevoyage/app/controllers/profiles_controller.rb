# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @recent_itineraries = current_user.itineraries.order(created_at: :desc).limit(5)
    @subscription_plan = current_user.subscription_plan || SubscriptionPlan.free_plan
    @journeys_remaining = current_user.journeys_remaining_this_month
  end

  def edit
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: 'Profile updated successfully.'
    else
      render :edit, alert: 'Please fix the errors below.'
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
