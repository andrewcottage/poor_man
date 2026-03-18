class Recipe::NutritionEstimator
  NutritionEstimate = Struct.new(
    :calories,
    :protein_grams,
    :carbs_grams,
    :fat_grams,
    :match_count,
    :missing_count,
    keyword_init: true
  )

  UNIT_ALIASES = {
    "cups" => "cup",
    "tablespoons" => "tbsp",
    "tablespoon" => "tbsp",
    "teaspoons" => "tsp",
    "teaspoon" => "tsp",
    "ounces" => "oz",
    "ounce" => "oz",
    "grams" => "g",
    "gram" => "g",
    "pounds" => "lb",
    "pound" => "lb",
    "cloves" => "clove"
  }.freeze

  FOOD_DATA = [
    { keywords: %w[flour all-purpose rye], unit: "cup", calories: 455, protein: 13.0, carbs: 95.0, fat: 1.2 },
    { keywords: %w[pasta], unit: "oz", calories: 105, protein: 3.8, carbs: 21.0, fat: 0.6 },
    { keywords: %w[olive oil], unit: "tbsp", calories: 119, protein: 0.0, carbs: 0.0, fat: 13.5 },
    { keywords: %w[chickpeas garbanzo], unit: "cup", calories: 269, protein: 14.5, carbs: 45.0, fat: 4.3 },
    { keywords: %w[lentils], unit: "cup", calories: 230, protein: 18.0, carbs: 40.0, fat: 0.8 },
    { keywords: %w[black beans beans], unit: "cup", calories: 227, protein: 15.2, carbs: 40.8, fat: 0.9 },
    { keywords: %w[garlic], unit: "clove", calories: 4, protein: 0.2, carbs: 1.0, fat: 0.0 },
    { keywords: %w[onion], unit: "cup", calories: 64, protein: 1.8, carbs: 14.9, fat: 0.2 },
    { keywords: %w[tomato tomatoes], unit: "cup", calories: 32, protein: 1.6, carbs: 7.0, fat: 0.4 },
    { keywords: %w[basil parsley cilantro spinach kale], unit: "cup", calories: 7, protein: 0.8, carbs: 1.1, fat: 0.1 },
    { keywords: %w[yeast], unit: "tsp", calories: 11, protein: 1.6, carbs: 1.4, fat: 0.1 },
    { keywords: %w[salt], unit: "tsp", calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0 },
    { keywords: %w[chili powder cumin paprika oregano], unit: "tbsp", calories: 22, protein: 1.0, carbs: 4.2, fat: 0.9 },
    { keywords: %w[tofu], unit: "oz", calories: 24, protein: 2.6, carbs: 0.7, fat: 1.4 },
    { keywords: %w[coconut milk], unit: "cup", calories: 445, protein: 4.6, carbs: 6.0, fat: 48.0 }
  ].freeze

  class << self
    def estimate(recipe:)
      totals = {
        calories: 0.0,
        protein_grams: 0.0,
        carbs_grams: 0.0,
        fat_grams: 0.0,
        match_count: 0,
        missing_count: 0
      }

      recipe.recipe_ingredients.ordered.each do |ingredient|
        food = find_food(ingredient.name)
        quantity = Recipe::QuantityMath.parse(ingredient.quantity) || Rational(1, 1)

        if food.present?
          normalized_unit = normalize_unit(ingredient.unit.presence || food[:unit])
          multiplier = normalized_unit == food[:unit] ? quantity.to_f : nil

          if multiplier.present?
            totals[:calories] += food[:calories] * multiplier
            totals[:protein_grams] += food[:protein] * multiplier
            totals[:carbs_grams] += food[:carbs] * multiplier
            totals[:fat_grams] += food[:fat] * multiplier
            totals[:match_count] += 1
          else
            totals[:missing_count] += 1
          end
        else
          totals[:missing_count] += 1
        end
      end

      servings = [ recipe.servings.to_i, 1 ].max
      NutritionEstimate.new(
        calories: (totals[:calories] / servings).round,
        protein_grams: (totals[:protein_grams] / servings).round(1),
        carbs_grams: (totals[:carbs_grams] / servings).round(1),
        fat_grams: (totals[:fat_grams] / servings).round(1),
        match_count: totals[:match_count],
        missing_count: totals[:missing_count]
      )
    end

    private

    def find_food(name)
      candidate = name.to_s.downcase
      FOOD_DATA.find do |entry|
        entry[:keywords].any? { |keyword| candidate.include?(keyword) }
      end
    end

    def normalize_unit(unit)
      normalized = unit.to_s.downcase.strip
      UNIT_ALIASES.fetch(normalized, normalized.presence)
    end
  end
end
