class RecipeMailer < ApplicationMailer
  default from: 'notifications@poorman.com'

  def new_recipe_notification(user, recipe)
    @user = user
    @recipe = recipe
    @recipe_url = recipe_url(@recipe.slug)
    
    mail(
      to: @user.email,
      subject: "New Recipe Added: #{@recipe.title}"
    )
  end
end