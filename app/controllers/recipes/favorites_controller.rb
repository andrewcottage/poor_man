class Recipes::FavoritesController < ApplicationController
  before_action :require_user!
  before_action :set_recipe

  def create
    unless Current.user.can_add_favorite?
      redirect_to pricing_path, alert: "Free accounts can save up to 50 favorites. Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} for unlimited saves."
      return
    end

    @favorite = Current.user.favorites.new
    @favorite.recipe = @recipe

    if @favorite.save
      redirect_to recipe_path(@recipe.slug), notice: "Recipe added to favorites"
    else
      redirect_to recipe_path(@recipe.slug), alert: "Could not add recipe to favorites"
    end
  end

  def destroy
    @favorite = Current.user.favorites.find(params[:id])
    @favorite.destroy

    redirect_to recipe_path(@recipe.slug), notice: "Recipe removed from favorites"
  end

  private

  def set_recipe
    @recipe = Recipe.visible_to(Current.user).find_by(slug: params[:recipe_slug]) || Recipe.visible_to(Current.user).find_by(id: params[:recipe_slug])
  end
end
