require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  test "shows pricing page and tracks visit" do
    assert_difference("AnalyticsEvent.count", 1) do
      get pricing_url
    end

    assert_response :success
    assert_select "p", text: "Stovaro Pro"
    assert_select "h2", text: "Free vs Stovaro Pro"
    assert_select "h2", text: "Buy extra generations without upgrading"
    assert_equal "pricing.viewed", AnalyticsEvent.order(:created_at).last.event_name
  end
end
