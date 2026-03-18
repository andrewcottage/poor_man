class Profiles::CollectionRecipesController < ApplicationController
  before_action :require_user!

  def create
    collection = Current.user.collections.find(params[:collection_id])
    recipe = Recipe.visible_to(Current.user).find(params[:recipe_id])
    collection_recipe = collection.collection_recipes.new(recipe: recipe)

    if collection_recipe.save
      redirect_back fallback_location: profiles_collection_path(collection), notice: "Recipe added to collection."
    else
      redirect_back fallback_location: profiles_collection_path(collection), alert: collection_recipe.errors.full_messages.to_sentence
    end
  end

  def destroy
    collection_recipe = CollectionRecipe.joins(:collection).where(collections: { user_id: Current.user.id }).find(params[:id])
    collection = collection_recipe.collection
    collection_recipe.destroy

    redirect_back fallback_location: profiles_collection_path(collection), notice: "Recipe removed from collection."
  end
end
