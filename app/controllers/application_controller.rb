class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?

  private

  def require_admin!
    return if current_user.admin?

    redirect_to root_path, alert: "That area is for admins."
  end
end
