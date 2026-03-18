class Recipe::IngredientScaler
  ScaledIngredient = Struct.new(:ingredient, :quantity, :display_text, keyword_init: true)

  def initialize(recipe:, target_servings:)
    @recipe = recipe
    @target_servings = [ target_servings.to_i, 1 ].max
  end

  def call
    factor = scaling_factor

    recipe.recipe_ingredients.ordered.map do |ingredient|
      scaled_quantity = scale_quantity(ingredient.quantity, factor)
      ScaledIngredient.new(
        ingredient: ingredient,
        quantity: scaled_quantity,
        display_text: build_display_text(ingredient, scaled_quantity)
      )
    end
  end

  private

  attr_reader :recipe, :target_servings

  def scaling_factor
    Rational(target_servings, recipe.servings.presence || 1)
  end

  def scale_quantity(quantity, factor)
    Recipe::QuantityMath.scaled_text(quantity, factor)
  end

  def build_display_text(ingredient, scaled_quantity)
    quantity_value = Recipe::QuantityMath.parse(scaled_quantity)
    unit = if quantity_value == Rational(1, 1)
      ingredient.unit.to_s.singularize.presence
    else
      ingredient.unit.presence
    end

    text = [
      scaled_quantity.presence,
      unit,
      ingredient.name
    ].compact.join(" ")

    return text if ingredient.notes.blank?

    "#{text}, #{ingredient.notes}"
  end
end
