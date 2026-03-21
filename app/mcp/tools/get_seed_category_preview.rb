class Tools::GetSeedCategoryPreview < Tools::BaseTool
  tool_name "get_seed_category_preview"
  description "Retrieve an existing admin seed category preview or published run by id."

  input_schema(
    type: "object",
    properties: {
      category_seed_run_id: { type: "integer", description: "Category seed run id" }
    },
    required: [ "category_seed_run_id" ]
  )

  def self.call(category_seed_run_id:, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    current_user = user(server_context: server_context)
    category_seed_run = current_user.category_seed_runs.find_by(id: category_seed_run_id) ||
      CategorySeedRun.find_by(id: category_seed_run_id)
    return error_response("Category seed preview not found") unless category_seed_run

    success_response(category_seed_preview_summary(category_seed_run))
  end
end
