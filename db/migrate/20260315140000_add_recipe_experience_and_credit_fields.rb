class AddRecipeExperienceAndCreditFields < ActiveRecord::Migration[8.0]
  def change
    change_table :recipes do |t|
      t.integer :servings, null: false, default: 4
      t.integer :nutrition_calories
      t.decimal :nutrition_protein_grams, precision: 8, scale: 2
      t.decimal :nutrition_carbs_grams, precision: 8, scale: 2
      t.decimal :nutrition_fat_grams, precision: 8, scale: 2
      t.integer :nutrition_match_count, null: false, default: 0
      t.integer :nutrition_missing_ingredients_count, null: false, default: 0
      t.datetime :nutrition_computed_at
    end

    change_table :users do |t|
      t.integer :generation_credits_balance, null: false, default: 0
    end

    change_table :recipe_generations do |t|
      t.string :dietary_preference
      t.string :skill_level
      t.text :avoid_ingredients
      t.text :ingredient_swaps
      t.text :customization_notes
      t.integer :servings, null: false, default: 4
      t.integer :target_difficulty
    end
  end
end
