# == Schema Information
#
# Table name: recipes
#
#  id          :integer          not null, primary key
#  blurb       :text
#  slug        :string
#  tag_names   :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  author_id   :integer
#  category_id :integer          not null
#
# Indexes
#
#  index_recipes_on_author_id    (author_id)
#  index_recipes_on_category_id  (category_id)
#  index_recipes_on_slug         (slug) UNIQUE
#
# Foreign Keys
#
#  author_id    (author_id => users.id)
#  category_id  (category_id => categories.id)
#
class Recipe < ApplicationRecord
  include Favoritable
  include Ratable
  include Stars
  include Editable
  include ImageGeneration
  include Taggable
  
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
