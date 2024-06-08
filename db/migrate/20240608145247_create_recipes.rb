class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title
      t.string :slug
      t.string :tags

      t.timestamps
    end
  end
end
