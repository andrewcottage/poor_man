class RecapMailer < ApplicationMailer
  def monthly_recap(user)
    @user = user
    @start_date = 1.month.ago.beginning_of_month
    @end_date = 1.month.ago.end_of_month

    # Fix the query to use user_id instead of user
    @favorite_count = user.recipes
                           .joins(:favorites)
                           .where(favorites: { created_at: @start_date..@end_date })
                           .count

    @comments_count = user.recipes.joins(:ratings)
                             .where(ratings: { created_at: @start_date..@end_date })
                             .count
    
    @average_rating = user.recipes.joins(:ratings)
                             .where(ratings: { created_at: @start_date..@end_date })
                             .average(:value)
                             .to_f.round(1)

    @recent_recipes = Recipe.order(created_at: :desc).limit(5)

    mail(
      to: @user.email,
      subject: "Your Monthly Recipe Recap for #{@start_date.strftime('%B %Y')}"
    )
  end
end 