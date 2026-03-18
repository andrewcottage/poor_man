class GroceryList::Builder
  AISLE_KEYWORDS = {
    "Produce" => %w[
      apple avocado basil broccoli carrot celery cilantro cucumber garlic ginger kale lemon lettuce lime mushroom onion parsley potato spinach tomato zucchini
    ],
    "Refrigerated" => %w[
      butter cheese cream egg eggs milk tofu yogurt
    ],
    "Bakery" => %w[
      bagel bread bun buns pita roll rolls tortilla tortillas
    ],
    "Frozen" => %w[
      frozen
    ],
    "Spices" => %w[
      allspice chili cinnamon cumin curry oregano paprika pepper rosemary salt thyme turmeric
    ],
    "Canned & Jarred" => %w[
      beans broth capers chickpeas coconut milk olives paste salsa sauce stock tahini tomatoes
    ]
  }.freeze

  def initialize(meal_plan:)
    @meal_plan = meal_plan
  end

  def call
    grocery_list = meal_plan.grocery_list || meal_plan.build_grocery_list(user: meal_plan.user)

    GroceryList.transaction do
      grocery_list.assign_attributes(
        user: meal_plan.user,
        title: "#{meal_plan.title} groceries",
        generated_at: Time.current
      )
      grocery_list.save!
      grocery_list.grocery_list_items.delete_all
      aggregated_items.each_with_index do |attributes, index|
        grocery_list.grocery_list_items.create!(attributes.merge(position: index + 1))
      end
    end

    grocery_list
  end

  private

  attr_reader :meal_plan

  def aggregated_items
    ingredient_groups.values.map { |ingredients| build_item(ingredients) }.sort_by { |item| [ item[:aisle], item[:name] ] }
  end

  def ingredient_groups
    meal_plan.planned_meals.includes(recipe: :recipe_ingredients).each_with_object({}) do |planned_meal, groups|
      planned_meal.recipe.recipe_ingredients.ordered.each do |ingredient|
        key = [
          normalize_name(ingredient.name),
          ingredient.unit.to_s.downcase.presence,
          aisle_for(ingredient.name)
        ]
        groups[key] ||= []
        groups[key] << ingredient
      end
    end
  end

  def build_item(ingredients)
    first_ingredient = ingredients.first

    {
      aisle: aisle_for(first_ingredient.name),
      name: first_ingredient.name,
      quantity: combined_quantity_for(ingredients),
      unit: normalized_unit_for(ingredients),
      notes: combined_notes_for(ingredients)
    }.compact
  end

  def normalize_name(name)
    name.to_s.downcase.squish
  end

  def normalized_unit_for(ingredients)
    ingredients.filter_map { |ingredient| ingredient.unit.to_s.downcase.presence }.uniq.one? ? ingredients.first.unit.to_s.downcase : nil
  end

  def combined_quantity_for(ingredients)
    quantities = ingredients.filter_map { |ingredient| ingredient.quantity.to_s.strip.presence }
    return if quantities.empty?

    parsed_quantities = quantities.map { |quantity| parse_quantity(quantity) }

    if parsed_quantities.all?
      format_quantity(parsed_quantities.sum)
    else
      quantities.uniq.join(" + ")
    end
  end

  def combined_notes_for(ingredients)
    notes = ingredients.filter_map { |ingredient| ingredient.notes.to_s.strip.presence }.uniq
    notes.join("; ").presence
  end

  def aisle_for(name)
    normalized = normalize_name(name)

    AISLE_KEYWORDS.each do |aisle, keywords|
      return aisle if keywords.any? { |keyword| normalized.include?(keyword) }
    end

    "Pantry"
  end

  def parse_quantity(value)
    case value
    when /\A\d+\z/
      Rational(value.to_i, 1)
    when /\A\d+\.\d+\z/
      Rational(value)
    when /\A\d+\/\d+\z/
      Rational(value)
    when /\A\d+\s+\d+\/\d+\z/
      whole, fraction = value.split(/\s+/, 2)
      Rational(whole.to_i, 1) + Rational(fraction)
    else
      nil
    end
  end

  def format_quantity(value)
    whole = value.to_i
    remainder = value - whole

    return whole.to_s if remainder.zero?
    return value.to_s if whole.zero?

    "#{whole} #{remainder}"
  end
end
