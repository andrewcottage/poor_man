class AddCostToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_monetize :recipes, :cost
  end
end
