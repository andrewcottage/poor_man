class Profiles::PlannedMealsController < ApplicationController
  before_action :require_pro_plan!
  before_action :set_planned_meal, only: %i[update destroy duplicate]

  def create
    meal_plan = MealPlan.for_week(user: Current.user, week_of: planned_meal_params[:scheduled_on])
    planned_meal = meal_plan.planned_meals.new(planned_meal_params)

    if planned_meal.save
      redirect_to profiles_meal_plan_path(week_of: meal_plan.week_of), notice: "Meal added to your plan."
    else
      redirect_to profiles_meal_plan_path(week_of: meal_plan.week_of), alert: planned_meal.errors.full_messages.to_sentence
    end
  end

  def update
    if @planned_meal.update(planned_meal_params)
      redirect_to profiles_meal_plan_path(week_of: @planned_meal.meal_plan.week_of), notice: "Meal plan updated."
    else
      redirect_to profiles_meal_plan_path(week_of: @planned_meal.meal_plan.week_of), alert: @planned_meal.errors.full_messages.to_sentence
    end
  end

  def destroy
    week_of = @planned_meal.meal_plan.week_of
    @planned_meal.destroy

    redirect_to profiles_meal_plan_path(week_of: week_of), notice: "Meal removed from your plan."
  end

  def duplicate
    duplicated_meal = @planned_meal.duplicate!

    redirect_to profiles_meal_plan_path(week_of: duplicated_meal.meal_plan.week_of), notice: "Meal copied."
  end

  private

  def set_planned_meal
    @planned_meal = Current.user.planned_meals.find(params[:id])
  end

  def planned_meal_params
    params.require(:planned_meal).permit(:recipe_id, :scheduled_on, :meal_type)
  end
end
