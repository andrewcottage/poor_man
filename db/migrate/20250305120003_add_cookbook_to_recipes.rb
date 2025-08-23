class AddCookbookToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_reference :recipes, :cookbook, null: true, foreign_key: true
    add_index :recipes, :cookbook_id
  end
end