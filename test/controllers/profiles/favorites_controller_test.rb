require "test_helper"

class Profiles::FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do 
    login
  end

  test "should get index" do
    get profiles_favorites_url
    assert_response :success
  end
end
