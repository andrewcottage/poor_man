# == Schema Information
#
# Table name: favorites
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_favorites_on_recipe_id              (recipe_id)
#  index_favorites_on_user_id                (user_id)
#  index_favorites_on_user_id_and_recipe_id  (user_id,recipe_id) UNIQUE
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#  user_id    (user_id => users.id)
#
class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :user_id, uniqueness: { scope: :recipe_id }
end
