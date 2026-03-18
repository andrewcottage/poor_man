class Admin::RecipeSubmissionsController < ApplicationController
  before_action :require_admin!
  before_action :set_recipe, only: %i[approve reject]

  def index
    @status = params[:status].presence_in(Recipe.moderation_statuses.keys + [ "all" ]) || "pending"
    scope = Recipe.includes(:author, :category).descending
    scope = scope.where(moderation_status: Recipe.moderation_statuses[@status]) unless @status == "all"
    @recipes = scope
  end

  def approve
    @recipe.update_columns(
      moderation_status: Recipe.moderation_statuses[:approved],
      reviewed_at: Time.current,
      reviewed_by_id: Current.user.id,
      rejection_reason: nil,
      updated_at: Time.current
    )

    redirect_to admin_recipe_submissions_path(status: "pending"), notice: "Recipe approved."
  end

  def reject
    @recipe.update_columns(
      moderation_status: Recipe.moderation_statuses[:rejected],
      reviewed_at: Time.current,
      reviewed_by_id: Current.user.id,
      rejection_reason: params[:rejection_reason].presence,
      updated_at: Time.current
    )

    redirect_to admin_recipe_submissions_path(status: "pending"), notice: "Recipe rejected."
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end
end
