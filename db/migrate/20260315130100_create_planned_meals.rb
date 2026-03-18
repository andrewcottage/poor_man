class CreatePlannedMeals < ActiveRecord::Migration[8.0]
  def change
    create_table :planned_meals do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.date :scheduled_on, null: false
      t.integer :meal_type, null: false, default: 2
      t.integer :position, null: false, default: 1

      t.timestamps
    end

    add_index :planned_meals, [ :meal_plan_id, :scheduled_on, :meal_type, :position ], name: "index_planned_meals_on_calendar_slot"
  end
end
