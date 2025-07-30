# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || app_index_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end