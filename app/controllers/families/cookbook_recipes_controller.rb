class Families::CookbookRecipesController < ApplicationController
  before_action :require_user!
  before_action :set_family
  before_action :require_family_member!
  before_action :set_cookbook

  def create
    recipe = Recipe.find(params[:recipe_id])
    @cookbook.family_cookbook_recipes.create!(recipe: recipe, added_by: Current.user.id)
    redirect_to family_cookbook_path(@family, @cookbook), notice: "Recipe added to #{@cookbook.name}."
  rescue ActiveRecord::RecordInvalid
    redirect_to family_cookbook_path(@family, @cookbook), alert: "Recipe is already in this cookbook."
  end

  def destroy
    cookbook_recipe = @cookbook.family_cookbook_recipes.find(params[:id])
    cookbook_recipe.destroy
    redirect_to family_cookbook_path(@family, @cookbook), notice: "Recipe removed."
  end

  private

  def set_family
    @family = Family.find(params[:family_id])
  end

  def require_family_member!
    redirect_to families_path, alert: "You are not a member of this family." unless @family.member?(Current.user)
  end

  def set_cookbook
    @cookbook = @family.family_cookbooks.find(params[:cookbook_id])
  end
end
