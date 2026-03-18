class CreateMealPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.date :week_of, null: false

      t.timestamps
    end

    add_index :meal_plans, [ :user_id, :week_of ], unique: true
  end
end
