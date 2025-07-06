class Recipes::GenerationController < ApplicationController
  before_action :require_admin!
  
  def create
    @recipe_generation = Recipe::Generation.new(recipe_params)

    if @recipe_generation.save
      redirect_to @recipe_generation, notice: "Recipe Generation is in progress."
    else
      render :new
    end
  end

  private

  def recipe_params
    params.require(:recipe_generation).permit(:prompt)
  end
end