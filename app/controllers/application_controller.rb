class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_current_user

  private

  def require_admin!
    redirect_to root_path, alert: 'You are not authorized to access this page' unless Current.user&.admin&.present?
  end

  def require_user!
    redirect_to login_path, alert: 'You must be logged in to access this page' if Current.user.nil?
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end
end
