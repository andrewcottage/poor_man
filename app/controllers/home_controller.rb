class HomeController < ApplicationController
  def index
    @latest = Recipe.latest.limit(12)
  end

  def about
  end
end
