class Profiles::FavoritesController < ApplicationController
  ITEMS = 12
  before_action :require_user!

  def index

    if params[:q]
      @pagy, @recipes = pagy(Current.user.favorite_recipes.where("title LIKE ?", "%#{params[:q]}%"), items: ITEMS)
    else
      @pagy, @recipes = pagy(Current.user.favorite_recipes, items: ITEMS)
    end
  end
end
