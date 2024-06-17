# == Schema Information
#
# Table name: recipes
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  title       :string
#  slug        :string
#  tags        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Recipe < ApplicationRecord
  has_rich_text :content

  has_one_attached :image

  belongs_to :category

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

end
