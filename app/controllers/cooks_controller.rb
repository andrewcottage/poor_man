class CooksController < ApplicationController
  def show
    @cook = User.find_by!(username: params[:username])
    @recipes = @cook.recipes.approved.includes(:category).order(created_at: :desc).limit(8)
    @reviews = @cook.ratings.includes(:recipe).order(created_at: :desc).limit(6)
    @recent_activity = @cook.recent_public_activity(limit: 6)
  end
end
