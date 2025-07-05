class AddRefIdToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :ref_id, :string
  end
end
