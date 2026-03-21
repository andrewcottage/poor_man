class Tools::ListSeedRuns < Tools::BaseTool
  tool_name "list_seed_runs"
  description "List recent admin seed runs with their publish state and preview links."

  def self.call(server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    success_response(Recipe::Generation.seed_runs.order(created_at: :desc).limit(10).map { |g| seed_preview_summary(g) })
  end
end
