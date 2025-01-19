class HomeController < ApplicationController
  def index
    @latest = Recipe.latest.descending.limit(6)
    @categories = Category.latest.limit(5)
  end

  def about
  end
end
