require "test_helper"

class GroceryList::BuilderTest < ActiveSupport::TestCase
  test "aggregates duplicate recipe ingredients into one grocery list item" do
    meal_plan = meal_plans(:pro_week)
    existing_list = grocery_lists(:pro_week_list)

    grocery_list = GroceryList::Builder.new(meal_plan: meal_plan).call

    assert_equal existing_list, grocery_list
    assert_equal existing_list.share_token, grocery_list.share_token
    assert_equal 4, grocery_list.grocery_list_items.count
    assert_equal "3", grocery_list.grocery_list_items.find_by(name: "flour").quantity
    assert_equal "cups", grocery_list.grocery_list_items.find_by(name: "flour").unit
    assert_equal "2", grocery_list.grocery_list_items.find_by(name: "salt").quantity
    assert_equal "Spices", grocery_list.grocery_list_items.find_by(name: "salt").aisle
    assert_equal "extra virgin", grocery_list.grocery_list_items.find_by(name: "olive oil").notes
  end
end
