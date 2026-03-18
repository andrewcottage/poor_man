class Profiles::FavoritesController < ApplicationController
  ITEMS = 12
  before_action :require_user!

  def index
    scope = Current.user.favorite_recipes.merge(Recipe.visible_to(Current.user))

    if params[:q]
      @pagy, @recipes = pagy(scope.where("title LIKE ?", "%#{params[:q]}%").descending, items: ITEMS)
    else
      @pagy, @recipes = pagy(scope.descending, items: ITEMS)
    end
  end
end
