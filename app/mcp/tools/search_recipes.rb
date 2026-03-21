class Tools::SearchRecipes < Tools::BaseTool
  tool_name "search_recipes"
  description "Search for recipes on the site. Use this to find recipes by keyword, filter by difficulty, prep time, cost, or dietary tags."

  input_schema(
    type: "object",
    properties: {
      query: { type: "string", description: "Search term for recipe title, description, or tags" },
      difficulty: { type: "integer", description: "Exact difficulty level 1-5 (1=very easy, 5=very hard)" },
      max_prep_time: { type: "integer", description: "Maximum prep time in minutes" },
      max_cost: { type: "number", description: "Maximum ingredient cost in USD" },
      dietary_tags: { type: "array", items: { type: "string" }, description: "Dietary tags to filter by (e.g. 'vegetarian', 'gluten-free')" },
      sort: { type: "string", enum: %w[newest rating popularity], description: "Sort order" }
    }
  )

  def self.call(query: nil, difficulty: nil, max_prep_time: nil, max_cost: nil, dietary_tags: nil, sort: nil, server_context:)
    params = {}
    params[:q] = query if query.present?
    params[:difficulty] = difficulty if difficulty.present?
    params[:prep_time] = max_prep_time if max_prep_time.present?
    params[:cost] = max_cost if max_cost.present?
    params[:dietary_tags] = dietary_tags if dietary_tags.present?
    params[:sort] = sort if sort.present?

    recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: params).call.limit(10)
    success_response(recipes.map { |r| recipe_summary(r) })
  end
end
