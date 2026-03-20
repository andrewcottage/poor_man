class Recipe::Generation::PublishJob < ApplicationJob
  queue_as :default

  def perform(recipe_generation)
    Recipe::GenerationPublisher.new(recipe_generation).call
  end
end
