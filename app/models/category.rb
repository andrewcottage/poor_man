# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  title          :string
#  slug           :string
#  description    :text
#  recipies_count :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Category < ApplicationRecord
  has_many :recipes, counter_cache: true, dependent: :nullify

  has_one_attached :image

  validates :image, attached: true
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end
