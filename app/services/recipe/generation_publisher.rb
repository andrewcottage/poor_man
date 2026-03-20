# frozen_string_literal: true

require "stringio"

class Recipe::GenerationPublisher
  class PublishError < StandardError; end

  FALLBACK_CATEGORY_IMAGE_PATH = Rails.root.join("app/assets/images/table-dinner.webp")

  def initialize(generation)
    @generation = generation
  end

  def call
    generation.with_lock do
      return generation.published_recipe if generation.published_recipe.present?

      ensure_publishable!

      category = find_or_create_category!
      recipe = build_recipe(category)
      attach_generation_images!(recipe)
      recipe.save!
      recipe.sync_recipe_ingredients!(structured_ingredients: recipe_data.fetch("ingredients", []))

      generation.update!(
        published_recipe: recipe,
        published_at: Time.current,
        seed_publish_error: nil
      )

      recipe
    end
  rescue StandardError => error
    generation.update_column(:seed_publish_error, error.message) if generation.persisted?
    raise
  end

  private

  attr_reader :generation

  def ensure_publishable!
    raise PublishError, "Generation is still in progress." unless generation.complete?
    raise PublishError, "Generation data is missing a recipe title." if recipe_title.blank?
  end

  def build_recipe(category)
    Recipe.new(
      title: recipe_title,
      blurb: recipe_data.fetch("blurb", "").to_s,
      instructions: recipe_data.fetch("instructions", "").to_s,
      difficulty: recipe_data["difficulty"].presence || 1,
      prep_time: recipe_data["prep_time"].presence || 30,
      servings: recipe_data["servings"].presence || generation.servings,
      cost: recipe_data["cost"].presence || 0,
      tag_names: Array(recipe_data["tags"]).join(", "),
      category: category,
      author: generation.user,
      reviewed_by: generation.user.admin? ? generation.user : nil,
      reviewed_at: generation.user.admin? ? Time.current : nil
    )
  end

  def attach_generation_images!(recipe)
    recipe.image.attach(
      io: StringIO.new(generation.image.download),
      filename: generation.image.filename.to_s,
      content_type: generation.image.content_type
    )

    generation.images.each do |image|
      recipe.images.attach(
        io: StringIO.new(image.download),
        filename: image.filename.to_s,
        content_type: image.content_type
      )
    end
  end

  def find_or_create_category!
    normalized_title = category_title.presence || "Dinner"
    normalized_slug = normalized_title.parameterize.presence || "dinner"

    existing = Category.find_by("LOWER(title) = ? OR LOWER(slug) = ?", normalized_title.downcase, normalized_slug.downcase)
    return existing if existing.present?

    category = Category.new(
      title: normalized_title.titleize,
      slug: unique_category_slug(normalized_slug),
      description: default_category_description(normalized_title)
    )
    attach_category_image!(category, normalized_title)
    category.save!
    category
  end

  def attach_category_image!(category, category_name)
    io, filename, content_type = generated_category_image_for(category_name)
    category.image.attach(io: io, filename: filename, content_type: content_type)
  end

  def generated_category_image_for(category_name)
    return fallback_category_image if openai_not_configured?

    image = OpenAI::ImageGenerator.new(
      prompt: <<~PROMPT.squish,
        Photorealistic editorial food photography representing #{category_name} recipes,
        with a cohesive spread of finished dishes and ingredients, natural light,
        realistic textures, clean composition, no text, no packaging, no illustration.
      PROMPT
      size: "1024x1024",
      basename: "category-#{category_name.parameterize}"
    ).call

    [ image.io, image.filename, image.content_type ]
  rescue StandardError
    fallback_category_image
  end

  def fallback_category_image
    raise PublishError, "Fallback category image is missing." unless FALLBACK_CATEGORY_IMAGE_PATH.exist?

    [
      StringIO.new(File.binread(FALLBACK_CATEGORY_IMAGE_PATH)),
      FALLBACK_CATEGORY_IMAGE_PATH.basename.to_s,
      Marcel::MimeType.for(FALLBACK_CATEGORY_IMAGE_PATH, name: FALLBACK_CATEGORY_IMAGE_PATH.basename.to_s)
    ]
  end

  def default_category_description(category_name)
    "Explore #{category_name.downcase} recipes with practical ingredients, polished instructions, and memorable weeknight-friendly ideas."
  end

  def unique_category_slug(base_slug)
    candidate = base_slug
    counter = 2

    while Category.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate
  end

  def recipe_data
    generation.data || {}
  end

  def recipe_title
    recipe_data["title"].to_s.squish
  end

  def category_title
    recipe_data["category"].to_s.squish
  end

  def openai_not_configured?
    !OpenAI::Config.configured?
  end
end
