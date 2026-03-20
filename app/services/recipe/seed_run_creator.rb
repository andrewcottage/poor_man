# frozen_string_literal: true

class Recipe::SeedRunCreator
  def initialize(user:)
    @user = user
  end

  def call(attributes:, auto_publish: false)
    generation = Recipe::Generation.new(attributes.merge(user: user, seed_tool: true, auto_publish_recipe: auto_publish))
    generation.skip_background_generation = true
    generation.save!

    run_step!(generation, "Recipe generation failed") { generation.generate_recipe }
    return generation if generation.seed_publish_error.present?

    run_step!(generation, "Hero image generation failed") { generation.generate_image }
    return generation if generation.seed_publish_error.present?

    run_step!(generation, "Gallery image generation failed") { generation.generate_images }
    return generation if generation.seed_publish_error.present?

    run_step!(generation, "Recipe publish failed") { Recipe::GenerationPublisher.new(generation).call } if auto_publish && generation.complete?

    generation
  end

  private

  attr_reader :user

  def run_step!(generation, prefix)
    yield
  rescue StandardError => error
    generation.update_column(:seed_publish_error, "#{prefix}: #{error.message}")
  end
end
