class Tools::PublishSeedRecipe < Tools::BaseTool
  tool_name "publish_seed_recipe"
  description "Publish an existing admin seed preview into a live recipe. This will create the category if needed."

  input_schema(
    type: "object",
    properties: {
      generation_id: { type: "integer", description: "Recipe generation id for the seed run" }
    },
    required: [ "generation_id" ]
  )

  def self.call(generation_id:, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    generation = Recipe::Generation.seed_runs.find_by(id: generation_id)
    return error_response("Seed preview not found") unless generation

    recipe = Recipe::GenerationPublisher.new(generation).call

    success_response(
      seed_preview_summary(generation.reload).merge(
        published: true,
        recipe: {
          title: recipe.title,
          slug: recipe.slug,
          url: recipe_path(recipe.slug)
        }
      )
    )
  rescue Recipe::GenerationPublisher::PublishError => e
    error_response(e.message)
  end
end
