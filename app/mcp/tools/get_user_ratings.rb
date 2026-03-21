class Tools::GetUserRatings < Tools::BaseTool
  tool_name "get_user_ratings"
  description "Get recipes the current user has rated, with their scores. Useful for understanding preferences."

  def self.call(server_context:)
    ratings = user(server_context: server_context).ratings.includes(:recipe).order(created_at: :desc).limit(20)
    success_response(ratings.map { |r|
      {
        recipe_title: r.recipe.title,
        recipe_slug: r.recipe.slug,
        rating: r.value,
        comment: r.comment,
        url: recipe_path(r.recipe.slug)
      }
    })
  end
end
