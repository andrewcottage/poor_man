require "test_helper"

class Billing::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
  end

  test "creates pending subscription from checkout completed event" do
    Billing::WebhookVerifier.stubs(:valid?).returns(true)

    payload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_123",
          client_reference_id: @user.id,
          customer: "cus_123",
          subscription: "sub_123",
          metadata: { plan: User::PLAN_PRO_MONTHLY, user_id: @user.id }
        }
      }
    }.to_json

    assert_difference("Subscription.count", 1) do
      post "/billing/webhooks/stripe", params: payload, headers: { "Content-Type" => "application/json", "Stripe-Signature" => "test" }
    end

    assert_response :success
    assert_equal "cus_123", Subscription.last.stripe_customer_id
  end

  test "updates user plan from subscription updated event" do
    @user.update!(stripe_customer_id: "cus_live")
    Billing::Config.stubs(:plan_from_price_id).with("price_monthly").returns(User::PLAN_PRO_MONTHLY)
    Billing::WebhookVerifier.stubs(:valid?).returns(true)

    payload = {
      type: "customer.subscription.updated",
      data: {
        object: {
          id: "sub_live",
          customer: "cus_live",
          status: "active",
          current_period_end: 2.weeks.from_now.to_i,
          items: {
            data: [
              {
                price: { id: "price_monthly" }
              }
            ]
          }
        }
      }
    }.to_json

    post "/billing/webhooks/stripe", params: payload, headers: { "Content-Type" => "application/json", "Stripe-Signature" => "test" }

    assert_response :success
    @user.reload
    assert @user.pro?
    assert_equal User::PLAN_PRO_MONTHLY, @user.plan
  end

  test "credits user balance from credit pack checkout event" do
    Billing::WebhookVerifier.stubs(:valid?).returns(true)

    payload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_credit_pack",
          client_reference_id: @user.id,
          customer: "cus_credit_123",
          payment_intent: "pi_credit_123",
          metadata: {
            kind: "credit_pack",
            pack_id: "extra_5",
            user_id: @user.id,
            price_id: "price_credit_5"
          }
        }
      }
    }.to_json

    assert_difference("CreditPurchase.count", 1) do
      post "/billing/webhooks/stripe", params: payload, headers: { "Content-Type" => "application/json", "Stripe-Signature" => "test" }
    end

    assert_response :success
    @user.reload
    assert_equal 5, @user.generation_credits_balance
    assert_equal "paid", CreditPurchase.last.status
  end
end
