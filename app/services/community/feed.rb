module Community
  class Feed
    Activity = Struct.new(:type, :user, :recipe, :rating, :created_at, keyword_init: true)

    def self.call(limit: 6)
      recipe_events = Recipe.approved.includes(:author).latest.limit(limit).map do |recipe|
        Activity.new(type: :recipe, user: recipe.author, recipe: recipe, created_at: recipe.created_at)
      end.select { |activity| activity.user.present? }

      review_events = Rating.includes(:user, :recipe).order(created_at: :desc).limit(limit).map do |rating|
        Activity.new(type: :review, user: rating.user, recipe: rating.recipe, rating: rating, created_at: rating.created_at)
      end.select { |activity| activity.user.present? }

      (recipe_events + review_events).sort_by(&:created_at).reverse.first(limit)
    end
  end
end
