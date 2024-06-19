class Rating < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  validates :value, presence: true, inclusion: { in: 1..5 }
  validates :recipe_id, uniqueness: { scope: :user_id }
end
