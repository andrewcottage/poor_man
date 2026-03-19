require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "logged in users see the account dropdown in the header" do
    login(users(:user))

    get root_url

    assert_response :success
    assert_select "[data-controller='account-dropdown']", count: 1
    assert_select "[data-account-dropdown-target='button']", count: 1
    assert_select "[data-account-dropdown-target='menu']", count: 1
  end
end
