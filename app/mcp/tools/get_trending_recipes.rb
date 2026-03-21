class Tools::GetTrendingRecipes < Tools::BaseTool
  tool_name "get_trending_recipes"
  description "Get the most popular and highly-rated recipes on the site right now."

  def self.call(server_context:)
    recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { sort: "popularity" }).call.limit(10)
    success_response(recipes.map { |r| recipe_summary(r) })
  end
end
