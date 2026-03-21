class Tools::PreviewSeedRecipe < Tools::BaseTool
  tool_name "preview_seed_recipe"
  description "Generate a photorealistic admin-only recipe preview with hero and gallery images. Use this before publishing unless the admin explicitly asks to publish immediately."

  input_schema(
    type: "object",
    properties: {
      prompt: { type: "string", description: "What recipe to create" },
      dietary_preference: { type: "string", description: "Optional dietary preference like vegan or gluten-free" },
      skill_level: { type: "string", description: "Optional skill level like beginner or advanced" },
      avoid_ingredients: { type: "string", description: "Comma-separated ingredients to avoid" },
      ingredient_swaps: { type: "string", description: "Optional requested swaps" },
      customization_notes: { type: "string", description: "Extra editorial notes for the model" },
      servings: { type: "integer", description: "Desired servings" },
      target_difficulty: { type: "integer", description: "Target difficulty 1-5" },
      publish_immediately: { type: "boolean", description: "Set true only when the admin clearly wants the content published right away" }
    },
    required: [ "prompt" ]
  )

  def self.call(prompt:, dietary_preference: nil, skill_level: nil, avoid_ingredients: nil, ingredient_swaps: nil, customization_notes: nil, servings: nil, target_difficulty: nil, publish_immediately: nil, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    auto_publish = ActiveModel::Type::Boolean.new.cast(publish_immediately) || false
    generation = Recipe::SeedRunCreator.new(user: user(server_context: server_context)).call(
      attributes: {
        prompt: prompt,
        dietary_preference: dietary_preference,
        skill_level: skill_level,
        avoid_ingredients: avoid_ingredients,
        ingredient_swaps: ingredient_swaps,
        customization_notes: customization_notes,
        servings: servings.presence || 4,
        target_difficulty: target_difficulty
      },
      auto_publish: auto_publish
    )

    success_response(seed_preview_summary(generation))
  end
end
