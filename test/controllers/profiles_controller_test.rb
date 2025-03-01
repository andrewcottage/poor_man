require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do 
    @user = users(:andrew)
    login
  end

  test "should get show" do
    get profile_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_profile_url(@user)
    assert_response :success
  end
end
