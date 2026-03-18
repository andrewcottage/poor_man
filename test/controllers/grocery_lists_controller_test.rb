require "test_helper"

class GroceryListsControllerTest < ActionDispatch::IntegrationTest
  test "shared grocery list is publicly viewable by token" do
    grocery_list = grocery_lists(:pro_week_list)

    get grocery_list_url(grocery_list.share_token)

    assert_response :success
    assert_select "h1", grocery_list.title
    assert_select "h2", "Pantry"
  end
end
