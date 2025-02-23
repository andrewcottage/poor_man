# == Schema Information
#
# Table name: ratings
#
#  id         :integer          not null, primary key
#  comment    :text(200)
#  title      :string
#  value      :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_ratings_on_recipe_id              (recipe_id)
#  index_ratings_on_recipe_id_and_user_id  (recipe_id,user_id) UNIQUE
#  index_ratings_on_user_id                (user_id)
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#  user_id    (user_id => users.id)
#
class Rating < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  attribute :user, default: -> { Current.user }

  validates :comment, :title, presence: true

  validates :value, presence: true, inclusion: { in: 1..5 }
  validates :recipe_id, uniqueness: { scope: :user_id }
end
