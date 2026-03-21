class Tools::QueueSeedRecipeBatch < Tools::BaseTool
  tool_name "queue_seed_recipe_batch"
  description "Queue a bulk batch of admin-only recipe previews across one or more categories. Use this for requests like generating multiple recipes per category or large preview batches."

  input_schema(
    type: "object",
    properties: {
      category_names: { type: "array", items: { type: "string" }, description: "Category titles to generate previews for" },
      count_per_category: { type: "integer", description: "How many recipe previews to queue per category" },
      dietary_preference: { type: "string", description: "Optional dietary preference like vegan or gluten-free" },
      skill_level: { type: "string", description: "Optional skill level like beginner or advanced" },
      avoid_ingredients: { type: "string", description: "Comma-separated ingredients to avoid" },
      ingredient_swaps: { type: "string", description: "Optional requested swaps" },
      customization_notes: { type: "string", description: "Extra editorial notes for the batch" },
      servings: { type: "integer", description: "Desired servings for each recipe" },
      target_difficulty: { type: "integer", description: "Target difficulty 1-5 for each recipe" },
      publish_immediately: { type: "boolean", description: "Set true only when the admin clearly wants the batch published automatically" }
    },
    required: [ "category_names", "count_per_category" ]
  )

  def self.call(category_names:, count_per_category:, dietary_preference: nil, skill_level: nil, avoid_ingredients: nil, ingredient_swaps: nil, customization_notes: nil, servings: nil, target_difficulty: nil, publish_immediately: nil, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    auto_publish = ActiveModel::Type::Boolean.new.cast(publish_immediately) || false
    result = Recipe::SeedBatchCreator.new(user: user(server_context: server_context)).call(
      category_names: category_names,
      count_per_category: count_per_category,
      dietary_preference: dietary_preference,
      skill_level: skill_level,
      avoid_ingredients: avoid_ingredients,
      ingredient_swaps: ingredient_swaps,
      customization_notes: customization_notes,
      servings: servings.presence || 4,
      target_difficulty: target_difficulty,
      auto_publish: auto_publish
    )

    success_response(
      status: "queued",
      message: "Queued #{result.total_count} recipe preview#{'s' if result.total_count != 1} across #{result.category_names.count} categor#{result.category_names.count == 1 ? 'y' : 'ies'}.",
      total_count: result.total_count,
      count_per_category: result.count_per_category,
      categories: result.category_names.map { |name|
        queued = result.generations.select { |g| inferred_category_from_notes(g) == name }
        {
          category: name,
          queued_count: queued.count,
          previews: queued.first(5).map { |g| queued_seed_preview_summary(g) }
        }
      },
      admin_seed_studio_url: admin_seed_recipes_path
    )
  rescue ArgumentError => e
    error_response(e.message)
  end
end
