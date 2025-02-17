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
#  author_id   :integer
#  blurb       :text
#
class Recipe < ApplicationRecord
  include Favoritable
  include Ratable
  include Stars
  include Editable

  has_rich_text :instructions

  has_one_attached :image
  has_many_attached :images

  belongs_to :category
  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true

  validates :image, attached: true
  validates :title, :slug, :instructions, :blurb, presence: true
  validates :slug, presence: true, uniqueness: true

  attribute :author, default: -> { Current.user || User.default_author } 
end
