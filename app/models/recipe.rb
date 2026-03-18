# == Schema Information
#
# Table name: recipes
#
#  id                                  :integer          not null, primary key
#  blurb                               :text
#  cost_cents                          :integer          default(0), not null
#  cost_currency                       :string           default("USD"), not null
#  difficulty                          :integer          default(0)
#  moderation_status                   :integer          default("pending"), not null
#  nutrition_calories                  :integer
#  nutrition_carbs_grams               :decimal(8, 2)
#  nutrition_computed_at               :datetime
#  nutrition_fat_grams                 :decimal(8, 2)
#  nutrition_match_count               :integer          default(0), not null
#  nutrition_missing_ingredients_count :integer          default(0), not null
#  nutrition_protein_grams             :decimal(8, 2)
#  prep_time                           :integer          default(0)
#  rejection_reason                    :text
#  reviewed_at                         :datetime
#  servings                            :integer          default(4), not null
#  slug                                :string
#  tag_names                           :string
#  title                               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  author_id                           :integer
#  category_id                         :integer          not null
#  reviewed_by_id                      :integer
#
# Indexes
#
#  index_recipes_on_author_id          (author_id)
#  index_recipes_on_category_id        (category_id)
#  index_recipes_on_moderation_status  (moderation_status)
#  index_recipes_on_reviewed_by_id     (reviewed_by_id)
#  index_recipes_on_slug               (slug) UNIQUE
#
# Foreign Keys
#
#  author_id       (author_id => users.id)
#  category_id     (category_id => categories.id)
#  reviewed_by_id  (reviewed_by_id => users.id)
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
  belongs_to :author, class_name: "User", foreign_key: "author_id", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :collection_recipes, dependent: :destroy
  has_many :collections, through: :collection_recipes
  has_many :planned_meals, dependent: :destroy
  has_many :recipe_ingredients, dependent: :destroy

  before_validation :ensure_slug
  before_validation :auto_approve_admin_submissions, on: :create
  before_validation :clear_review_metadata_for_pending

  enum :moderation_status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  scope :pending_review, -> { where(moderation_status: moderation_statuses[:pending]) }

  validates :image, attached: true
  validates :title, :slug, :instructions, :blurb, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :servings, numericality: { only_integer: true, greater_than: 0 }

  attribute :author, default: -> { Current.user || User.default_author }
  attr_writer :ingredient_list, :structured_ingredient_payload

  monetize :cost_cents

  def self.visible_to(user)
    return all if user&.admin?
    return approved if user.blank?

    approved.or(where(author_id: user.id))
  end

  def self.from_generation(generation_id)
    generation = Recipe::Generation.find_by(id: generation_id)
    return nil unless generation&.data&.present?

    data = generation.data

    recipe = new(
      title: data["title"],
      blurb: data["blurb"],
      instructions: data["instructions"],
      difficulty: data["difficulty"] || 1,
      prep_time: data["prep_time"] || 30,
      cost: data["cost"] || 0,
      servings: data["servings"] || 4,
      tag_names: data["tags"]&.join(", "),
      category: find_category_by_name(data["category"]),
      slug: generate_unique_slug(data["title"])
    )
    recipe.structured_ingredient_payload = data["ingredients"]

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

  def visible_to?(user)
    return true if approved?
    return false if user.blank?

    user.admin? || author_id == user.id
  end

  def mark_pending_review!
    self.moderation_status = :pending
    self.reviewed_at = nil
    self.reviewed_by = nil
    self.rejection_reason = nil
  end

  def ingredient_list
    return @ingredient_list if @ingredient_list.present?
    return Recipe::IngredientParser.format(@structured_ingredient_payload) if @structured_ingredient_payload.present?
    return Recipe::IngredientParser.format(recipe_ingredients.ordered) if persisted? && recipe_ingredients.exists?

    ""
  end

  def structured_ingredient_payload
    @structured_ingredient_payload
  end

  def sync_recipe_ingredients!(ingredient_list: nil, structured_ingredients: nil)
    parsed_ingredients = if structured_ingredients.present?
      Recipe::IngredientParser.parse_structured(structured_ingredients)
    elsif ingredient_list.present?
      Recipe::IngredientParser.parse(ingredient_list)
    else
      Recipe::IngredientParser.parse(instructions.body.to_plain_text)
    end

    transaction do
      recipe_ingredients.delete_all
      parsed_ingredients.each do |attributes|
        recipe_ingredients.create!(attributes)
      end
    end

    recalculate_nutrition!
  end

  def scaled_ingredients(target_servings = servings)
    Recipe::IngredientScaler.new(
      recipe: self,
      target_servings: normalized_servings(target_servings)
    ).call
  end

  def normalized_servings(value)
    candidate = value.to_i
    return servings if candidate <= 0

    candidate
  end

  def instruction_steps
    Recipe::InstructionStepParser.parse(instructions.body.to_s)
  end

  def nutrition_available?
    nutrition_computed_at.present? && nutrition_match_count.positive?
  end

  def nutrition_coverage_label
    return "Nutrition estimate unavailable" unless nutrition_computed_at.present?

    "#{nutrition_match_count} matched, #{nutrition_missing_ingredients_count} unmatched ingredients"
  end

  def recalculate_nutrition!
    return unless persisted?

    estimate = Recipe::NutritionEstimator.estimate(recipe: self)

    update_columns(
      nutrition_calories: estimate.calories,
      nutrition_protein_grams: estimate.protein_grams,
      nutrition_carbs_grams: estimate.carbs_grams,
      nutrition_fat_grams: estimate.fat_grams,
      nutrition_match_count: estimate.match_count,
      nutrition_missing_ingredients_count: estimate.missing_count,
      nutrition_computed_at: Time.current
    )
  end

  def related_recipes(limit: 4)
    tag_ids = tags.ids
    related_scope = self.class.approved.where.not(id: id).left_joins(:tags)
    related_scope = related_scope.where(
      "recipes.category_id = ? OR tags.id IN (?)",
      category_id,
      tag_ids.presence || [ 0 ]
    )

    related_scope
      .group("recipes.id")
      .order(Arel.sql("COUNT(DISTINCT tags.id) DESC, recipes.created_at DESC"))
      .limit(limit)
  end

  private

  def auto_approve_admin_submissions
    self.moderation_status = :approved if author&.admin?
  end

  def clear_review_metadata_for_pending
    return unless pending?

    self.reviewed_at = nil
    self.reviewed_by = nil
    self.rejection_reason = nil
  end

  def ensure_slug
    return if slug.present? || title.blank?

    base_slug = title.parameterize.presence || "recipe"
    candidate_slug = base_slug
    counter = 2

    while self.class.where.not(id: id).exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end

  def self.find_category_by_name(category_name)
    return Category.first if category_name.blank?

    # Try to find existing category by title (case insensitive)
    category = Category.find_by("LOWER(title) = ?", category_name.downcase)
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
