# == Schema Information
#
# Table name: planned_meals
#
#  id           :integer          not null, primary key
#  meal_type    :integer          default("dinner"), not null
#  position     :integer          default(1), not null
#  scheduled_on :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  meal_plan_id :integer          not null
#  recipe_id    :integer          not null
#
# Indexes
#
#  index_planned_meals_on_calendar_slot  (meal_plan_id,scheduled_on,meal_type,position)
#  index_planned_meals_on_meal_plan_id   (meal_plan_id)
#  index_planned_meals_on_recipe_id      (recipe_id)
#
# Foreign Keys
#
#  meal_plan_id  (meal_plan_id => meal_plans.id)
#  recipe_id     (recipe_id => recipes.id)
#
class PlannedMeal < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :recipe

  enum :meal_type, {
    breakfast: 0,
    lunch: 1,
    dinner: 2,
    snack: 3
  }

  before_validation :assign_next_position, on: :create

  validates :scheduled_on, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validate :scheduled_on_within_meal_plan_week

  delegate :user, to: :meal_plan

  scope :for_day, ->(date) { where(scheduled_on: date) }
  scope :ordered, -> { order(:scheduled_on, :meal_type, :position, :id) }

  def duplicate!
    meal_plan.planned_meals.create!(
      recipe: recipe,
      scheduled_on: scheduled_on,
      meal_type: meal_type
    )
  end

  private

  def assign_next_position
    return if position.present? && position.positive?
    return if meal_plan.blank? || scheduled_on.blank? || meal_type.blank?

    sibling_scope = meal_plan.planned_meals.where(scheduled_on: scheduled_on, meal_type: meal_type)
    self.position = sibling_scope.maximum(:position).to_i + 1
  end

  def scheduled_on_within_meal_plan_week
    return if meal_plan.blank? || scheduled_on.blank?
    return if scheduled_on.between?(meal_plan.week_of, meal_plan.week_of + 6.days)

    errors.add(:scheduled_on, "must be inside the selected meal-planning week")
  end
end
