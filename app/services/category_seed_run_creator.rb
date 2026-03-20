# frozen_string_literal: true

class CategorySeedRunCreator
  def initialize(user:)
    @user = user
  end

  def call(prompt:, auto_publish: false)
    category_seed_run = user.category_seed_runs.create!(prompt: prompt)

    run_step!(category_seed_run, "Category generation failed") do
      category_seed_run.update!(data: generate_data(prompt))
    end
    return category_seed_run if category_seed_run.seed_publish_error.present?

    run_step!(category_seed_run, "Category image generation failed") do
      attach_preview_image!(category_seed_run)
    end
    return category_seed_run if category_seed_run.seed_publish_error.present?

    run_step!(category_seed_run, "Category publish failed") do
      CategorySeedRunPublisher.new(category_seed_run).call
    end if auto_publish && category_seed_run.complete?

    category_seed_run
  end

  private

  attr_reader :user

  def generate_data(prompt)
    OpenAI::Config.ensure_configured!
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4.1",
        messages: [
          {
            role: "user",
            content: formatted_prompt(prompt)
          }
        ]
      }
    )

    OpenAI::StructuredOutput.parse_json_object!(response.dig("choices", 0, "message", "content"))
  end

  def attach_preview_image!(category_seed_run)
    generated_image = OpenAI::ImageGenerator.new(
      prompt: formatted_image_prompt(category_seed_run),
      size: "1536x1024",
      basename: "category_seed_#{category_seed_run.id}"
    ).call

    category_seed_run.image.attach(
      io: generated_image.io,
      filename: generated_image.filename,
      content_type: generated_image.content_type
    )
  end

  def formatted_prompt(prompt)
    <<~PROMPT
      Create a single recipe-site category from this admin request: "#{prompt}".

      Respond with ONLY valid JSON in this shape:
      {
        "title": "Category Title",
        "slug": "category-slug",
        "description": "1-2 sentence description of what recipes belong in this category."
      }

      Rules:
      - Pick one category only.
      - The title should be broad and useful for a recipe site.
      - The slug must be URL-friendly and lowercase with hyphens.
      - The description should sound editorial and help the category page feel curated.
      - No markdown, no commentary, JSON only.
    PROMPT
  end

  def formatted_image_prompt(category_seed_run)
    data = category_seed_run.data || {}

    <<~PROMPT.squish
      Photorealistic editorial food photography representing the "#{data["title"]}" recipe category.
      Show a cohesive spread of finished dishes that belong in this category, natural light, realistic
      textures, premium cookbook styling, clean composition, no text, no packaging, no illustration.
      Category description: #{data["description"]}.
    PROMPT
  end

  def run_step!(category_seed_run, prefix)
    yield
  rescue StandardError => error
    category_seed_run.update_column(:seed_publish_error, "#{prefix}: #{error.message}")
  end
end
