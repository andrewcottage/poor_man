class Recipe::Generation::GenerateImagesJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    recipe_generation.generate_images
    recipe_generation.publish_seed_recipe_if_ready_later
  end
end
