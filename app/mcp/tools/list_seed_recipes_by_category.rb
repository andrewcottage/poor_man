class Tools::ListSeedRecipesByCategory < Tools::BaseTool
  tool_name "list_seed_recipes_by_category"
  description "List recent admin seed recipe runs grouped by category. Useful after queueing a large batch."

  input_schema(
    type: "object",
    properties: {
      category_names: { type: "array", items: { type: "string" }, description: "Optional category titles to filter by" }
    }
  )

  def self.call(category_names: nil, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    category_names = Array(category_names).map(&:to_s).reject(&:blank?)
    generations = Recipe::Generation.seed_runs.order(created_at: :desc).limit(100)
    grouped = generations.group_by { |g|
      g.data["category"].presence || inferred_category_from_notes(g) || "Uncategorized"
    }
    grouped.select! { |cat, _| cat.in?(category_names) } if category_names.any?

    success_response(grouped.map { |cat_name, gens|
      { category: cat_name, runs: gens.first(10).map { |g| seed_preview_summary(g) } }
    })
  end
end
