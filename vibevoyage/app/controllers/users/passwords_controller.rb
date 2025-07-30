# app/controllers/users/passwords_controller.rb
class Users::PasswordsController < Devise::PasswordsController
  protected

  def after_resetting_password_path_for(resource)
    app_index_path
  end
end