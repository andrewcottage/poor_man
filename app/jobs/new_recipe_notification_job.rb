class NewRecipeNotificationJob < ApplicationJob
  queue_as :default

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)
    
    # Find all users who want to be notified about new recipes
    User.where(notify_new_recipes: true).find_each do |user|
      # Don't send notification to the recipe author
      next if user == recipe.author
      
      RecipeMailer.new_recipe_notification(user, recipe).deliver_now
    end
  end
end