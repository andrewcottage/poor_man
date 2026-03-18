module Profiles::MealPlansHelper
  def meal_type_options(selected = nil)
    options_for_select(
      PlannedMeal.meal_types.keys.map { |meal_type| [ meal_type.humanize, meal_type ] },
      selected
    )
  end
end
