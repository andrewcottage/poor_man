class Tools::BaseTool < MCP::Tool
  URL_HELPERS = Rails.application.routes.url_helpers

  class << self
    def user(server_context:)
      server_context[:user]
    end

    def require_admin!(server_context:)
      user = user(server_context: server_context)
      unless user.admin?
        return error_response("This tool is only available to admins.")
      end
      nil
    end

    def success_response(data)
      MCP::Tool::Response.new([ { type: "text", text: data.to_json } ])
    end

    def error_response(message)
      MCP::Tool::Response.new([ { type: "text", text: { error: message }.to_json } ], error: true)
    end

    def recipe_summary(recipe)
      {
        title: recipe.title,
        slug: recipe.slug,
        blurb: recipe.blurb&.truncate(120),
        difficulty: recipe.difficulty,
        prep_time: recipe.prep_time,
        category: recipe.category&.title,
        url: URL_HELPERS.recipe_path(recipe.slug)
      }
    end

    def seed_preview_summary(generation)
      {
        generation_id: generation.id,
        prompt: generation.prompt,
        status: seed_run_status(generation),
        title: generation.data["title"],
        blurb: generation.data["blurb"],
        category: generation.data["category"],
        tags: Array(generation.data["tags"]),
        preview_url: URL_HELPERS.admin_seed_recipe_path(generation),
        image_urls: seed_image_urls(generation),
        published: generation.published_recipe.present?,
        published_recipe_url: generation.published_recipe.present? ? URL_HELPERS.recipe_path(generation.published_recipe.slug) : nil,
        seed_publish_error: generation.seed_publish_error
      }
    end

    def queued_seed_preview_summary(generation)
      {
        generation_id: generation.id,
        prompt: generation.prompt,
        status: seed_run_status(generation),
        preview_url: URL_HELPERS.admin_seed_recipe_path(generation)
      }
    end

    def category_seed_preview_summary(category_seed_run)
      {
        category_seed_run_id: category_seed_run.id,
        prompt: category_seed_run.prompt,
        status: category_seed_run_status(category_seed_run),
        title: category_seed_run.data["title"],
        slug: category_seed_run.data["slug"],
        description: category_seed_run.data["description"],
        preview_url: URL_HELPERS.admin_seed_category_path(category_seed_run),
        image_urls: category_seed_image_urls(category_seed_run),
        published: category_seed_run.published_category.present?,
        published_category_url: category_seed_run.published_category.present? ? URL_HELPERS.category_path(category_seed_run.published_category.slug) : nil,
        seed_publish_error: category_seed_run.seed_publish_error
      }
    end

    def seed_run_status(generation)
      return "published" if generation.published_recipe.present?
      return "needs_attention" if generation.seed_publish_error.present?
      return "ready" if generation.complete?
      "generating"
    end

    def category_seed_run_status(category_seed_run)
      return "published" if category_seed_run.published_category.present?
      return "needs_attention" if category_seed_run.seed_publish_error.present?
      return "ready" if category_seed_run.complete?
      "generating"
    end

    def seed_image_urls(generation)
      urls = []
      urls << URL_HELPERS.rails_blob_path(generation.image, only_path: true) if generation.image.attached?
      urls.concat(generation.images.map { |image| URL_HELPERS.rails_blob_path(image, only_path: true) })
      urls
    end

    def category_seed_image_urls(category_seed_run)
      return [] unless category_seed_run.image.attached?
      [ URL_HELPERS.rails_blob_path(category_seed_run.image, only_path: true) ]
    end

    def inferred_category_from_notes(generation)
      match = generation.customization_notes.to_s.match(/exact category title "([^"]+)"/i)
      match&.captures&.first
    end
  end
end
