class Recipes::FavoritesController < ApplicationController
  before_action :require_user!
  before_action :set_recipe
  def create
    @favorite = Current.user.favorites.new
    @favorite.recipe = @recipe

    if @favorite.save
      redirect_to recipe_path(@recipe.slug), notice: 'Recipe added to favorites'
    else
      redirect_to recipe_path(@recipe.slug), alert: 'Could not add recipe to favorites'
    end
  end

  def destroy
    @favorite = Current.user.favorites.find(params[:id])
    @favorite.destroy

    redirect_to recipe_path(@recipe.slug), notice: 'Recipe removed from favorites'
  end

  private

  def set_recipe
    @recipe = Recipe.find_by(slug: params[:recipe_slug]) || Recipe.find_by(id: params[:recipe_slug]) 
  end
end
