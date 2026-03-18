require "test_helper"

class Billing::CheckoutSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
  end

  test "creates checkout session when billing is configured" do
    login(@user)
    Billing::Config.stubs(:configured?).returns(true)
    Billing::Config.stubs(:price_id_for).with(User::PLAN_PRO_MONTHLY).returns("price_monthly")

    client = mock
    client.expects(:create_checkout_session).returns(
      {
        "id" => "cs_123",
        "url" => "https://checkout.stripe.test/session",
        "customer" => "cus_123",
        "subscription" => "sub_123"
      }
    )
    Billing::StripeClient.stubs(:new).returns(client)

    assert_difference("Subscription.count", 1) do
      post billing_checkout_sessions_url, params: { plan: User::PLAN_PRO_MONTHLY }
    end

    assert_redirected_to "https://checkout.stripe.test/session"
    subscription = Subscription.last
    assert_equal "pending", subscription.status
    assert_equal User::PLAN_PRO_MONTHLY, subscription.plan
  end

  test "redirects to pricing when billing is not configured" do
    login(@user)
    Billing::Config.stubs(:configured?).returns(false)

    post billing_checkout_sessions_url, params: { plan: User::PLAN_PRO_MONTHLY }

    assert_redirected_to pricing_path
  end

  test "creates credit pack checkout session when configured" do
    login(@user)
    Billing::Config.stubs(:credit_pack_configured?).with("extra_5").returns(true)
    Billing::Config.stubs(:credit_pack_price_id).with("extra_5").returns("price_credit_5")

    client = mock
    client.expects(:create_credit_pack_checkout_session).returns(
      {
        "id" => "cs_credit_123",
        "url" => "https://checkout.stripe.test/credit-pack",
        "customer" => "cus_credit_123",
        "payment_intent" => "pi_credit_123"
      }
    )
    Billing::StripeClient.stubs(:new).returns(client)

    assert_difference("CreditPurchase.count", 1) do
      post billing_checkout_sessions_url, params: { credit_pack_id: "extra_5" }
    end

    assert_redirected_to "https://checkout.stripe.test/credit-pack"
    purchase = CreditPurchase.last
    assert_equal "pending", purchase.status
    assert_equal "extra_5", purchase.pack_id
    assert_equal 5, purchase.credits
  end
end
