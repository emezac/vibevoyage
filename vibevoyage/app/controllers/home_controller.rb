class HomeController < ApplicationController
  # Allow public access to home page
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # Redirect authenticated users to the app
    if user_signed_in?
      redirect_to app_index_path
    end
    # Otherwise show the landing page
  end
end
