# Preview all emails at http://localhost:3000/rails/mailers/recap_mailer
class RecapMailerPreview < ActionMailer::Preview
  def monthly_recap
    # Create some sample data for preview
    user = User.first || User.create!(
      name: "Test User",
      email: "test@example.com"
    )

    # Create a recipe if none exists
    unless user.recipes.exists?
      recipe = user.recipes.create!(
        title: "Sample Recipe",
        # Add other required attributes
      )
      
      # Add some sample interactions
      other_user = User.second || User.create!(
        name: "Other User",
        email: "other@example.com"
      )
      
      recipe.favorites.create!(user: other_user)
      recipe.comments.create!(user: other_user, content: "Great recipe!")
      recipe.ratings.create!(user: other_user, value: 5)
    end

    RecapMailer.monthly_recap(user)
  end
end 