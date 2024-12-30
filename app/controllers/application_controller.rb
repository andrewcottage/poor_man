class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_current_user

  private

  def require_admin!
    return unless Current.user&.admin&.present?

    redirect_to new_session_path(
      return_to: request.fullpath
    ), alert: 'You are not authorized to access this page' 
  end

  def require_user!
    return unless Current.user.present?

    redirect_to new_session_path(
      return_to: request.fullpath
    ), alert: 'You must be logged in to access this page'
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end
end
