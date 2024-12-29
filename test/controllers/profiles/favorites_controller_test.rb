require "test_helper"

class Profiles::FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get profiles_favorites_index_url
    assert_response :success
  end
end
