# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: [:index] # ✅ Solo index público
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Redirect after login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || app_index_path
  end

  # Redirect after logout
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # Check if user can create journeys
  def ensure_can_create_journey
    unless current_user&.can_create_journey?
      if request.format.json?
        render json: {
          success: false,
          error: 'subscription_limit_reached',
          message: 'You have reached your monthly journey limit. Please upgrade your subscription.',
          upgrade_url: subscriptions_path
        }
      else
        redirect_to subscriptions_path, alert: 'You have reached your monthly journey limit. Please upgrade to continue.'
      end
    end
  end

  # Handle subscription expired
  def check_subscription_status
    return unless user_signed_in?
    
    if current_user.subscription_expired? && current_user.subscription_status == 'active'
      current_user.update!(subscription_status: 'expired')
      flash.now[:alert] = 'Your subscription has expired. Please renew to continue enjoying premium features.'
    end
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
