class CreateGroceryLists < ActiveRecord::Migration[8.0]
  def change
    create_table :grocery_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meal_plan, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.datetime :generated_at
      t.string :share_token, null: false

      t.timestamps
    end

    add_index :grocery_lists, :share_token, unique: true
  end
end
