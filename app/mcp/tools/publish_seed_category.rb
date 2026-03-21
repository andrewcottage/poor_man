class Tools::PublishSeedCategory < Tools::BaseTool
  tool_name "publish_seed_category"
  description "Publish an existing admin category preview into a live category."

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

    category_seed_run = CategorySeedRun.find_by(id: category_seed_run_id)
    return error_response("Category seed preview not found") unless category_seed_run

    category = CategorySeedRunPublisher.new(category_seed_run).call

    success_response(
      category_seed_preview_summary(category_seed_run.reload).merge(
        published: true,
        category_record: {
          title: category.title,
          slug: category.slug,
          url: category_path(category.slug)
        }
      )
    )
  rescue CategorySeedRunPublisher::PublishError => e
    error_response(e.message)
  end
end
