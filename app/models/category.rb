# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  description    :text
#  recipies_count :integer
#  slug           :string
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_categories_on_slug  (slug) UNIQUE
#
class Category < ApplicationRecord
  has_many :recipes, counter_cache: true

  has_one_attached :image

  validates :image, attached: true
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end
