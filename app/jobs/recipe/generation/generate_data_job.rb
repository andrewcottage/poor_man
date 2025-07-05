class Recipe::Generation::GenerateDataJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    recipe_generation.generate_recipe_data
  end
end
