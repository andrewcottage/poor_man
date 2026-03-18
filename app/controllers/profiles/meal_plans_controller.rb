class Profiles::MealPlansController < ApplicationController
  before_action :require_pro_plan!

  def show
    @meal_plan = MealPlan.for_week(user: Current.user, week_of: selected_week)
    @planner_recipe_groups = planner_recipe_groups
    @grocery_list = @meal_plan.grocery_list
  end

  private

  def selected_week
    params[:week_of].presence || Date.current
  end

  def planner_recipe_groups
    favorites = Current.user.favorite_recipes.visible_to(Current.user).order(:title).distinct.limit(8)
    recents = Recipe.visible_to(Current.user).order(created_at: :desc).limit(8)
    library = Recipe.visible_to(Current.user).order(:title)

    [
      [ "Favorites", favorites.map { |recipe| [ recipe.title, recipe.id ] } ],
      [ "Recently added", recents.map { |recipe| [ recipe.title, recipe.id ] } ],
      [ "All recipes", library.map { |recipe| [ recipe.title, recipe.id ] } ]
    ].reject { |(_, options)| options.empty? }
  end
end
