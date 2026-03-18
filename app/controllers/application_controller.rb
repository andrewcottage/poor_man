class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_current_user
  around_action :switch_locale



  private

  def switch_locale(&action)
    locale = params[:locale] ||
             request.headers["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first ||
             I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def require_admin!
    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: "You are not authorized to access this page" unless Current.user&.admin&.present?
  end

  def require_user!
    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: "You must be logged in to access this page" if Current.user.nil?
  end

  def require_pro_plan!
    require_user!
    return if performed?
    return if Current.user&.pro?

    redirect_to pricing_path, alert: "#{Billing::PlanCatalog::PRO_DISPLAY_NAME} is required for meal planning and grocery lists."
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
    Current.user ||= User.find_by(api_key: api_key_from_request) if api_key_from_request.present?
  end

  def api_key_from_request
    bearer_token.presence || request.headers["X-Api-Key"].presence
  end

  def bearer_token
    scheme, token = request.authorization.to_s.split(" ", 2)
    return if scheme.blank? || token.blank?
    token if scheme.casecmp("Bearer").zero?
  end
end
