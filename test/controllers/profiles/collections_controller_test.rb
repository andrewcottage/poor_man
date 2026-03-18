require "test_helper"

class Profiles::CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @pro_user = users(:pro_user)
    @collection = collections(:weeknights)
  end

  test "shows collections index" do
    login(@user)

    get profiles_collections_url

    assert_response :success
    assert_select "h1", "Your collections"
    assert_select "h2", text: @collection.name
  end

  test "free user is blocked from second collection" do
    login(@user)

    assert_no_difference("Collection.count") do
      post profiles_collections_url, params: { collection: { name: "Party Food", description: "Weekend picks" } }
    end

    assert_redirected_to pricing_path
  end

  test "pro user can create another collection" do
    login(@pro_user)

    assert_difference("Collection.count", 1) do
      post profiles_collections_url, params: { collection: { name: "Meal Prep", description: "Batch cook ideas" } }
    end

    assert_redirected_to profiles_collection_path(Collection.last)
  end
end
