# frozen_string_literal: true

class CategorySeedRunCreator
  def initialize(user:)
    @user = user
  end

  def call(prompt:, auto_publish: false)
    category_seed_run = user.category_seed_runs.create!(prompt: prompt)

    category_seed_run.update!(data: generate_data(prompt))
    attach_preview_image!(category_seed_run)

    CategorySeedRunPublisher.new(category_seed_run).call if auto_publish

    category_seed_run
  end

  private

  attr_reader :user

  def generate_data(prompt)
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

    JSON.parse(response.dig("choices", 0, "message", "content"))
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
end
