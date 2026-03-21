class Tools::ListSeedCategoryRuns < Tools::BaseTool
  tool_name "list_seed_category_runs"
  description "List recent admin category seed runs with their publish state and preview links."

  def self.call(server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    success_response(CategorySeedRun.recent_first.limit(10).map { |r| category_seed_preview_summary(r) })
  end
end
