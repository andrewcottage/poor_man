class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.integer :value, null: false

      t.string :title
      t.text :comment, limit: 200

      t.timestamps
    end

    add_index :ratings, [:recipe_id, :user_id], unique: true
  end
end
