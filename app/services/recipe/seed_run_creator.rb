# frozen_string_literal: true

class Recipe::SeedRunCreator
  def initialize(user:)
    @user = user
  end

  def call(attributes:, auto_publish: false)
    generation = Recipe::Generation.new(attributes.merge(user: user, seed_tool: true, auto_publish_recipe: auto_publish))
    generation.skip_background_generation = true
    generation.save!

    generation.generate_recipe
    generation.generate_image
    generation.generate_images

    Recipe::GenerationPublisher.new(generation).call if auto_publish

    generation
  end

  private

  attr_reader :user
end
