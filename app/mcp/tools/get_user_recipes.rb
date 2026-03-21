class Tools::GetUserRecipes < Tools::BaseTool
  tool_name "get_user_recipes"
  description "Get recipes authored/submitted by the current user."

  def self.call(server_context:)
    recipes = user(server_context: server_context).recipes.limit(20)
    success_response(recipes.map { |r| recipe_summary(r) })
  end
end
