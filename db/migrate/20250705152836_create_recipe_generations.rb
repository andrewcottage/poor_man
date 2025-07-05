class CreateRecipeGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_generations do |t|
      t.belongs_to :user, null: false, foreign_key: true, index: true

      t.text :prompt
      t.jsonb :data, default: {}

      t.timestamps
    end
  end
end
