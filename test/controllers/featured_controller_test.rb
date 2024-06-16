require "test_helper"

class FeaturedControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get featured_index_url
    assert_response :success
  end
end
