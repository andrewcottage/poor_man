class AddAuthorToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_reference :recipes, :author, null: true, foreign_key: { to_table: :users }
  end
end
