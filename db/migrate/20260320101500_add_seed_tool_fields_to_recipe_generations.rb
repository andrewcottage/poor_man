class AddSeedToolFieldsToRecipeGenerations < ActiveRecord::Migration[8.1]
  def change
    change_table :recipe_generations, bulk: true do |t|
      t.boolean :seed_tool, default: false, null: false
      t.boolean :auto_publish_recipe, default: false, null: false
      t.references :published_recipe, foreign_key: { to_table: :recipes }
      t.datetime :published_at
      t.text :seed_publish_error
    end
  end
end
