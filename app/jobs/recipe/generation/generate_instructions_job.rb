class Recipe::Generation::GenerateInstructionsJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    recipe_generation.generate_instructions
  end
end
