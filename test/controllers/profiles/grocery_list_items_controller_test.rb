require "test_helper"

class Profiles::GroceryListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pro_user = users(:pro_user)
    @item = grocery_list_items(:pro_week_flour)
  end

  test "owner can check off a grocery list item" do
    login(@pro_user)

    patch profiles_grocery_list_item_url(@item), params: {
      grocery_list_item: { checked: true }
    }

    assert_redirected_to profiles_grocery_list_path(@item.grocery_list)
    assert @item.reload.checked?
  end
end
