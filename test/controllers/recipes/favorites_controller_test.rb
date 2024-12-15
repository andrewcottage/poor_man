require "test_helper"

class Recipes::FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get recipes_favorites_create_url
    assert_response :success
  end
end
