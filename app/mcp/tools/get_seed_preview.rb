class Tools::GetSeedPreview < Tools::BaseTool
  tool_name "get_seed_preview"
  description "Retrieve an existing admin seed preview or published run by generation id."

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

    current_user = user(server_context: server_context)
    generation = current_user.recipe_generations.seed_runs.find_by(id: generation_id) ||
      Recipe::Generation.seed_runs.find_by(id: generation_id)
    return error_response("Seed preview not found") unless generation

    success_response(seed_preview_summary(generation))
  end
end
