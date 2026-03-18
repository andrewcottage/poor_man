# == Schema Information
#
# Table name: collections
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_collections_on_user_id           (user_id)
#  index_collections_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Collection < ApplicationRecord
  belongs_to :user

  has_many :collection_recipes, dependent: :destroy
  has_many :recipes, through: :collection_recipes

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
