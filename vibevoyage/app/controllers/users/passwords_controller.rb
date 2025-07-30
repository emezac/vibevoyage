# app/controllers/users/passwords_controller.rb
class Users::PasswordsController < Devise::PasswordsController
  # Skip authentication for password reset pages
  skip_before_action :authenticate_user!
  
  protected

  def after_resetting_password_path_for(resource)
    app_index_path
  end
end