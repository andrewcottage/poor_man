class CreateGroceryListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :grocery_list_items do |t|
      t.references :grocery_list, null: false, foreign_key: true
      t.string :name, null: false
      t.string :quantity
      t.string :unit
      t.string :notes
      t.string :aisle, null: false, default: "Pantry"
      t.boolean :checked, null: false, default: false
      t.integer :position, null: false, default: 1

      t.timestamps
    end

    add_index :grocery_list_items, [ :grocery_list_id, :aisle, :position ], name: "index_grocery_list_items_on_grouping"
  end
end
