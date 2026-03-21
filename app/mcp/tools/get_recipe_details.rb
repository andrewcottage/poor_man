class Tools::GetRecipeDetails < Tools::BaseTool
  tool_name "get_recipe_details"
  description "Get full details for a specific recipe including ingredients, instructions, nutrition, and ratings."

  input_schema(
    type: "object",
    properties: {
      slug: { type: "string", description: "The recipe's URL slug" }
    },
    required: [ "slug" ]
  )

  def self.call(slug:, server_context:)
    recipe = Recipe.approved.find_by(slug: slug)
    return error_response("Recipe not found") unless recipe

    success_response(
      title: recipe.title,
      slug: recipe.slug,
      blurb: recipe.blurb,
      difficulty: recipe.difficulty,
      prep_time: recipe.prep_time,
      servings: recipe.servings,
      cost: recipe.cost_cents.to_f / 100,
      category: recipe.category&.title,
      tags: recipe.tags.pluck(:name),
      ingredients: recipe.recipe_ingredients.map { |i| "#{i.quantity} #{i.unit} #{i.name}".strip },
      instructions: recipe.instructions.to_s.gsub(/<[^>]+>/, " ").squish.truncate(500),
      average_rating: recipe.ratings.average(:value)&.round(1),
      rating_count: recipe.ratings.count,
      favorite_count: recipe.favorites.count,
      author: recipe.author&.username,
      url: recipe_path(recipe.slug)
    )
  end
end
