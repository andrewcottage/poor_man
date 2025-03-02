class Profiles::RecipesController < ApplicationController
  ITEMS = 12
  before_action :require_user!

  def index

    if params[:q]
      @pagy, @recipes = pagy(Current.user.recipes.where("title LIKE ?", "%#{params[:q]}%"), items: ITEMS)
    else
      @pagy, @recipes = pagy(Current.user.recipes.descending, items: ITEMS)
    end
  end
end
