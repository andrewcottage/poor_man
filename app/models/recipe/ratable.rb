module Recipe::Ratable
  extend ActiveSupport::Concern

  included do
    has_many :ratings
    has_many :reviewers, through: :ratings, source: :user
  end

  def rating 
    ratings.average(:value) || 0
  end

  def current_user_rating
    Current.user.ratings.find_by(recipe_id: id)
  end
end