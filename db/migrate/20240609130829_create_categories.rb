class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :title
      t.string :slug, index: { unique: true }
      t.text :description
      t.integer :recipies_count

      t.timestamps
    end
  end
end
