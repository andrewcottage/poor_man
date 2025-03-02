class AddDifficultyToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :difficulty, :integer, default: 0
  end
end
