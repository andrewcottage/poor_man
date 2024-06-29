# == Schema Information
#
# Table name: ratings
#
#  id         :integer          not null, primary key
#  recipe_id  :integer          not null
#  user_id    :integer          not null
#  value      :integer          not null
#  comment    :text(200)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Rating < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  attribute :user, default: -> { Current.user }

  validates :comment, :title, presence: true

  validates :value, presence: true, inclusion: { in: 1..5 }
  validates :recipe_id, uniqueness: { scope: :user_id }
end
