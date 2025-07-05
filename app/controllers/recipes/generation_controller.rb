class Recipes::GenerationController < ApplicationController
  before_action :require_admin!
  
  def create
    @recipe_generation = Recipe::Generation.new(recipe_params)
    
    if @recipe_generation.save
      redirect_to @recipe_generation, notice: "Recipe Generation was is in progress."
    else
      render :new
    end
  end

  private

  def recipe_params
    params.require(:recipe).permit(:title, :image, :slug, :instructions, :tag_names, :blurb, :difficulty, :prep_time, :category_id, :cost, images: [])
  end
end