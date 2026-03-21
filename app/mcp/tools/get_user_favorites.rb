class Tools::GetUserFavorites < Tools::BaseTool
  tool_name "get_user_favorites"
  description "Get the current user's favorite/liked recipes."

  def self.call(server_context:)
    recipes = user(server_context: server_context).favorite_recipes.approved.limit(20)
    success_response(recipes.map { |r| recipe_summary(r) })
  end
end
