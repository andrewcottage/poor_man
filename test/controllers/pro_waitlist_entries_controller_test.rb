require "test_helper"

class ProWaitlistEntriesControllerTest < ActionDispatch::IntegrationTest
  test "creates waitlist entry" do
    assert_difference("ProWaitlistEntry.count", 1) do
      assert_difference("AnalyticsEvent.where(event_name: 'pricing.waitlist_joined').count", 1) do
        post pro_waitlist_entries_url, params: {
          pro_waitlist_entry: {
            email: "new_waitlist@example.com",
            source: "pricing_page",
            plan_preference: "monthly"
          }
        }
      end
    end

    assert_redirected_to pricing_path
  end
end
