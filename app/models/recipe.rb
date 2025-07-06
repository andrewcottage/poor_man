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

  def self.from_generation(generation_id)
    generation = Recipe::Generation.find_by(id: generation_id)
    return nil unless generation&.data&.present?
    
    data = generation.data
    
    recipe = new(
      title: data['title'],
      blurb: data['blurb'],
      instructions: data['instructions'],
      difficulty: data['difficulty'] || 1,
      prep_time: data['prep_time'] || 30,
      cost: data['cost'] || 0,
      tag_names: data['tags']&.join(', '),
      category: find_category_by_name(data['category']),
      slug: generate_unique_slug(data['title'])
    )
    
    recipe
  end

  def use_generated_images(generation_id)
    generation = Recipe::Generation.find_by(id: generation_id)
    return unless generation
    
    # Copy main image if it exists
    if generation.image.attached?
      image.attach(
        io: StringIO.new(generation.image.blob.download),
        filename: generation.image.blob.filename,
        content_type: generation.image.blob.content_type
      )
    end
    
    # Copy additional images
    generation.images.each do |gen_image|
      images.attach(
        io: StringIO.new(gen_image.blob.download),
        filename: gen_image.blob.filename,
        content_type: gen_image.blob.content_type
      )
    end
  end

  private

  def self.find_category_by_name(category_name)
    return Category.first if category_name.blank?
    
    # Try to find existing category by title (case insensitive)
    category = Category.find_by('LOWER(title) = ?', category_name.downcase)
    category || Category.first
  end

  def self.generate_unique_slug(title)
    base_slug = title.parameterize
    slug = base_slug
    counter = 1
    
    while exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    slug
  end
end
