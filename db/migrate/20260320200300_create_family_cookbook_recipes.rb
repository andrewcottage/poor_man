class CreateFamilyCookbookRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :family_cookbook_recipes do |t|
      t.references :family_cookbook, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :family_cookbook_recipes, [:family_cookbook_id, :recipe_id], unique: true, name: "index_family_cookbook_recipes_uniqueness"
  end
end
