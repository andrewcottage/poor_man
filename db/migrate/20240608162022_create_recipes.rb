class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :category, null: false, foreign_key: true

      t.string :title
      t.string :slug, index: { unique: true }
      t.string :tags

      t.timestamps
    end
  end
end
