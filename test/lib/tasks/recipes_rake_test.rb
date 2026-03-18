require "test_helper"
require "rake"

class RecipesRakeTest < ActiveSupport::TestCase
  TASKS = %w[
    recipes:parse_ingredients
    recipes:backfill_nutrition
    recipes:backfill_metadata
  ].freeze

  setup do
    self.class.load_tasks_once
    reset_tasks
    clear_env
  end

  teardown do
    clear_env
    reset_tasks
  end

  test "backfill_metadata parses ingredients and recalculates nutrition" do
    recipe = recipes(:pending_recipe)
    recipe.recipe_ingredients.delete_all
    recipe.update_columns(
      nutrition_calories: nil,
      nutrition_protein_grams: nil,
      nutrition_carbs_grams: nil,
      nutrition_fat_grams: nil,
      nutrition_match_count: 0,
      nutrition_missing_ingredients_count: 0,
      nutrition_computed_at: nil
    )
    ENV["RECIPE_ID"] = recipe.id.to_s

    output, = capture_io do
      Rake::Task["recipes:backfill_metadata"].invoke
    end

    recipe.reload
    assert recipe.recipe_ingredients.exists?
    assert recipe.nutrition_computed_at.present?
    assert_match "Parsed ingredients and recalculated nutrition", output
  end

  test "backfill_nutrition skips recipes without structured ingredients" do
    recipe = recipes(:pending_recipe)
    recipe.recipe_ingredients.delete_all
    recipe.update_columns(nutrition_computed_at: nil)
    ENV["RECIPE_ID"] = recipe.id.to_s

    _, error_output = capture_io do
      Rake::Task["recipes:backfill_nutrition"].invoke
    end

    recipe.reload
    assert_nil recipe.nutrition_computed_at
    assert_match "Skipped #{recipe.id}", error_output
  end

  def self.load_tasks_once
    return if @tasks_loaded

    Rails.application.load_tasks
    @tasks_loaded = true
  end

  private

  def reset_tasks
    TASKS.each { |task_name| Rake::Task[task_name].reenable }
  end

  def clear_env
    ENV.delete("RECIPE_ID")
    ENV.delete("ONLY_MISSING")
    ENV.delete("BATCH_SIZE")
  end
end
