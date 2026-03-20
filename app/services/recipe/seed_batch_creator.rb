# frozen_string_literal: true

class Recipe::SeedBatchCreator
  MAX_TOTAL_PREVIEWS = 60
  VARIATION_HINTS = [
    "weeknight-friendly",
    "crowd-pleasing",
    "seasonal",
    "comforting",
    "fresh and modern",
    "budget-conscious",
    "highly shareable",
    "make-ahead friendly"
  ].freeze

  BatchResult = Struct.new(:generations, :category_names, :count_per_category, keyword_init: true) do
    def total_count
      generations.count
    end
  end

  def initialize(user:)
    @user = user
  end

  def call(category_names:, count_per_category:, dietary_preference: nil, skill_level: nil,
    avoid_ingredients: nil, ingredient_swaps: nil, customization_notes: nil,
    servings: 4, target_difficulty: nil, auto_publish: false)
    names = Array(category_names).map { |name| name.to_s.squish }.reject(&:blank?).uniq
    count = count_per_category.to_i

    raise ArgumentError, "Select at least one category." if names.empty?
    raise ArgumentError, "Count per category must be at least 1." if count < 1
    raise ArgumentError, "Bulk preview requests are limited to #{MAX_TOTAL_PREVIEWS} recipes at a time." if names.size * count > MAX_TOTAL_PREVIEWS

    generations = names.flat_map do |category_name|
      count.times.map do |index|
        create_generation(
          category_name: category_name,
          sequence: index + 1,
          dietary_preference: dietary_preference,
          skill_level: skill_level,
          avoid_ingredients: avoid_ingredients,
          ingredient_swaps: ingredient_swaps,
          customization_notes: customization_notes,
          servings: servings,
          target_difficulty: target_difficulty,
          auto_publish: ActiveModel::Type::Boolean.new.cast(auto_publish) || false
        )
      end
    end

    BatchResult.new(generations: generations, category_names: names, count_per_category: count)
  end

  private

  attr_reader :user

  def create_generation(category_name:, sequence:, dietary_preference:, skill_level:, avoid_ingredients:,
    ingredient_swaps:, customization_notes:, servings:, target_difficulty:, auto_publish:)
    user.recipe_generations.create!(
      seed_tool: true,
      auto_publish_recipe: auto_publish,
      prompt: prompt_for(category_name, sequence),
      dietary_preference: dietary_preference,
      skill_level: skill_level,
      avoid_ingredients: avoid_ingredients,
      ingredient_swaps: ingredient_swaps,
      customization_notes: merged_customization_notes(category_name, sequence, customization_notes),
      servings: servings,
      target_difficulty: target_difficulty
    )
  end

  def prompt_for(category_name, sequence)
    variation_hint = VARIATION_HINTS[(sequence - 1) % VARIATION_HINTS.length]
    %(Create an original #{variation_hint} recipe concept that clearly belongs in the "#{category_name}" category for Stovaro.)
  end

  def merged_customization_notes(category_name, sequence, customization_notes)
    instructions = [
      %(Use the exact category title "#{category_name}" in the generated JSON category field.),
      %(Make this recipe distinct from the other recipes in this batch; this is variation ##{sequence}.)
    ]
    instructions << customization_notes.to_s.squish if customization_notes.present?
    instructions.join(" ")
  end
end
