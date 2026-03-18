require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get privacy" do
    get privacy_pages_url
    assert_response :success
    assert_select "a[href='mailto:privacy@stovaro.com']", text: "privacy@stovaro.com"
  end

  test "should get terms" do
    get terms_pages_url
    assert_response :success
    assert_select "a[href='mailto:support@stovaro.com']", text: "support@stovaro.com"
  end

  test "should get about" do
    get about_pages_url
    assert_response :success
  end
end
