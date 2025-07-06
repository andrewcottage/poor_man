class Recipe::Generation::GenerateImageJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    recipe_generation.generate_image
  end
end
