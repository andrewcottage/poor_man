class Tools::PreviewSeedCategory < Tools::BaseTool
  tool_name "preview_seed_category"
  description "Generate an admin-only category preview with a title, slug, editorial description, and photorealistic image. Use this for standalone category creation requests."

  input_schema(
    type: "object",
    properties: {
      prompt: { type: "string", description: "What category to create" },
      publish_immediately: { type: "boolean", description: "Set true only when the admin clearly wants the category published right away" }
    },
    required: [ "prompt" ]
  )

  def self.call(prompt:, publish_immediately: nil, server_context:)
    admin_error = require_admin!(server_context: server_context)
    return admin_error if admin_error

    auto_publish = ActiveModel::Type::Boolean.new.cast(publish_immediately) || false
    category_seed_run = CategorySeedRunCreator.new(user: user(server_context: server_context)).call(
      prompt: prompt,
      auto_publish: auto_publish
    )

    success_response(category_seed_preview_summary(category_seed_run))
  end
end
