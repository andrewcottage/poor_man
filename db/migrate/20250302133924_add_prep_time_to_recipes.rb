class AddPrepTimeToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :prep_time, :integer, default: 0
  end
end
