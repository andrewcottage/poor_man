class Recipe::Generation::GenerateImagesJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    recipe_generation.generate_images
  end
end
