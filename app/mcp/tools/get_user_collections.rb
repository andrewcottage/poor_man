class Tools::GetUserCollections < Tools::BaseTool
  tool_name "get_user_collections"
  description "Get the current user's recipe collections."

  def self.call(server_context:)
    collections = user(server_context: server_context).collections.includes(collection_recipes: :recipe).limit(10)
    success_response(collections.map { |c|
      {
        name: c.name,
        description: c.description,
        recipes: c.recipes.limit(10).map { |r| recipe_summary(r) }
      }
    })
  end
end
