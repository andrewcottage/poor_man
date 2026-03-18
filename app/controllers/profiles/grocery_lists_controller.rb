class Profiles::GroceryListsController < ApplicationController
  before_action :require_pro_plan!
  before_action :set_grocery_list, only: :show

  def create
    meal_plan = MealPlan.for_week(user: Current.user, week_of: params[:week_of])
    grocery_list = GroceryList::Builder.new(meal_plan: meal_plan).call

    redirect_to profiles_grocery_list_path(grocery_list), notice: "Grocery list is ready."
  end

  def show
  end

  private

  def set_grocery_list
    @grocery_list = Current.user.grocery_lists.find(params[:id])
  end
end
