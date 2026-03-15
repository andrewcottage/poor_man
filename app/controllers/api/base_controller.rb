class Api::BaseController < ApplicationController
  skip_forgery_protection

  before_action :require_api_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def require_api_user!
    return if Current.user.present?

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_unprocessable(entity)
    render json: { errors: entity.errors.full_messages }, status: :unprocessable_entity
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end
end
