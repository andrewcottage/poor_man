class GroceryListsController < ApplicationController
  def show
    @grocery_list = GroceryList.find_by!(share_token: params[:share_token])
  end
end
