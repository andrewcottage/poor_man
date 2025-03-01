require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get privacy" do
    get privacy_pages_url
    assert_response :success
  end

  test "should get terms" do
    get terms_pages_url
    assert_response :success
  end

  test "should get about" do
    get about_pages_url
    assert_response :success
  end
end
