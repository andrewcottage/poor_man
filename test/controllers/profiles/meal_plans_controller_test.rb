require "test_helper"

class Profiles::MealPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pro_user = users(:pro_user)
    @free_user = users(:user)
    @meal_plan = meal_plans(:pro_week)
  end

  test "free user is redirected to pricing" do
    login(@free_user)

    get profiles_meal_plan_url

    assert_redirected_to pricing_path
  end

  test "pro user can view weekly meal planner" do
    login(@pro_user)

    get profiles_meal_plan_url(week_of: @meal_plan.week_of)

    assert_response :success
    assert_select "h1", text: /Week of/
    assert_select "h3", text: "Pizza"
    assert_select "optgroup[label='Favorites']"
    assert_select "a[href='#{profiles_grocery_list_path(grocery_lists(:pro_week_list))}']"
  end
end
