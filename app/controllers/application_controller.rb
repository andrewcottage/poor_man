class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_current_user

  private

  def require_admin!
    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: 'You are not authorized to access this page' unless Current.user&.admin&.present?
  end

  def require_user!
    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: 'You must be logged in to access this page' if Current.user.nil?
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end
end
