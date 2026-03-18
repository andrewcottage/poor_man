require "test_helper"

class Profiles::GroceryListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pro_user = users(:pro_user)
    @grocery_list = grocery_lists(:pro_week_list)
  end

  test "pro user can regenerate grocery list from meal plan" do
    login(@pro_user)

    assert_no_difference("GroceryList.count") do
      post profiles_grocery_lists_url, params: { week_of: meal_plans(:pro_week).week_of }
    end

    assert_redirected_to profiles_grocery_list_path(@grocery_list)
    @grocery_list.reload
    assert_equal 4, @grocery_list.grocery_list_items.count
    assert_equal "3", @grocery_list.grocery_list_items.find_by(name: "flour").quantity
    assert_equal "Spices", @grocery_list.grocery_list_items.find_by(name: "salt").aisle
  end

  test "owner can view grocery list" do
    login(@pro_user)

    get profiles_grocery_list_url(@grocery_list)

    assert_response :success
    assert_select "h1", @grocery_list.title
    assert_select "p", text: /Share URL/
  end
end
