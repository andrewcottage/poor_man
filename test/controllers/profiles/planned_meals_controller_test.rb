require "test_helper"

class Profiles::PlannedMealsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pro_user = users(:pro_user)
    @free_user = users(:user)
    @planned_meal = planned_meals(:pro_week_pizza)
  end

  test "pro user can create a planned meal for a new week" do
    login(@pro_user)

    assert_difference("MealPlan.count", 1) do
      assert_difference("PlannedMeal.count", 1) do
        post profiles_planned_meals_url, params: {
          planned_meal: {
            recipe_id: recipes(:pizza).id,
            scheduled_on: "2026-03-24",
            meal_type: "dinner"
          }
        }
      end
    end

    created_plan = MealPlan.order(:created_at).last
    assert_equal Date.parse("2026-03-23"), created_plan.week_of
    assert_redirected_to profiles_meal_plan_path(week_of: created_plan.week_of)
  end

  test "pro user can move a planned meal within the week" do
    login(@pro_user)

    patch profiles_planned_meal_url(@planned_meal), params: {
      planned_meal: {
        scheduled_on: "2026-03-18",
        meal_type: "lunch"
      }
    }

    assert_redirected_to profiles_meal_plan_path(week_of: @planned_meal.meal_plan.week_of)
    assert_equal Date.parse("2026-03-18"), @planned_meal.reload.scheduled_on
    assert_equal "lunch", @planned_meal.meal_type
  end

  test "pro user can duplicate a planned meal" do
    login(@pro_user)

    assert_difference("PlannedMeal.count", 1) do
      post duplicate_profiles_planned_meal_url(@planned_meal)
    end

    duplicate = PlannedMeal.order(:created_at).last
    assert_equal @planned_meal.recipe, duplicate.recipe
    assert_equal @planned_meal.scheduled_on, duplicate.scheduled_on
  end

  test "pro user can remove a planned meal" do
    login(@pro_user)

    assert_difference("PlannedMeal.count", -1) do
      delete profiles_planned_meal_url(@planned_meal)
    end

    assert_redirected_to profiles_meal_plan_path(week_of: meal_plans(:pro_week).week_of)
  end

  test "free user is redirected to pricing when creating planned meals" do
    login(@free_user)

    assert_no_difference("PlannedMeal.count") do
      post profiles_planned_meals_url, params: {
        planned_meal: {
          recipe_id: recipes(:pizza).id,
          scheduled_on: "2026-03-17",
          meal_type: "dinner"
        }
      }
    end

    assert_redirected_to pricing_path
  end
end
