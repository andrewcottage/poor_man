class HomeController < ApplicationController
  def index
    @latest = Recipe.approved.includes(:author, :category).latest.descending.limit(6)
    @trending = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { sort: "popularity" }).call.limit(4)
    @community_activity = Community::Feed.call(limit: 6)
    @popular_contributors = User.trending_contributors(limit: 4)
    @categories = Category.latest.limit(5)
  end

  def about
  end
end
