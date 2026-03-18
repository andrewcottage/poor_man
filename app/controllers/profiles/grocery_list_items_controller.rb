class Profiles::GroceryListItemsController < ApplicationController
  before_action :require_pro_plan!

  def update
    grocery_list_item = GroceryListItem.joins(:grocery_list).where(id: params[:id], grocery_lists: { user_id: Current.user.id }).first

    if grocery_list_item&.update(grocery_list_item_params)
      redirect_to profiles_grocery_list_path(grocery_list_item.grocery_list), notice: "Grocery list updated."
    else
      redirect_back fallback_location: profiles_meal_plan_path, alert: "Could not update that grocery item."
    end
  end

  private

  def grocery_list_item_params
    params.require(:grocery_list_item).permit(:checked)
  end
end
