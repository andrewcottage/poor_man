module Recipe::Favoritable
  extend ActiveSupport::Concern

  included do
    has_many :favorites, dependent: :destroy
    has_many :favoriters, through: :favorites, source: :user
  end


  def current_user_favorite
    Current.user&.favorites&.find_by(recipe_id: id)
  end
end