# == Schema Information
#
# Table name: recipes
#
#  id            :integer          not null, primary key
#  blurb         :text
#  cost_cents    :integer          default(0), not null
#  cost_currency :string           default("USD"), not null
#  difficulty    :integer          default(0)
#  prep_time     :integer          default(0)
#  slug          :string
#  tag_names     :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :integer
#  category_id   :integer          not null
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
  include AiGeneration
  
  has_rich_text :instructions

  has_one_attached :image
  has_many_attached :images

  belongs_to :category
  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true

  validates :image, attached: true
  validates :title, :slug, :instructions, :blurb, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  attribute :author, default: -> { Current.user || User.default_author } 

  monetize :cost_cents
end
