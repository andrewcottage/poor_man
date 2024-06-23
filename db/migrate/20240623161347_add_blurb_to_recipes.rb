class AddBlurbToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :blurb, :text
  end
end
