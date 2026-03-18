class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string :quantity
      t.string :unit
      t.string :name, null: false
      t.string :notes
      t.text :raw, null: false

      t.timestamps
    end

    add_index :recipe_ingredients, [ :recipe_id, :position ]
  end
end
