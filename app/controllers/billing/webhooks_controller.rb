class Billing::WebhooksController < ActionController::Base
  skip_forgery_protection

  def stripe
    payload = request.raw_post
    signature = request.headers["Stripe-Signature"]

    unless Billing::WebhookVerifier.valid?(
      payload: payload,
      signature_header: signature,
      secret: Billing::Config.webhook_secret
    )
      head :unauthorized
      return
    end

    event = JSON.parse(payload)
    object = event.dig("data", "object") || {}

    case event["type"]
    when "checkout.session.completed"
      if object.dig("metadata", "kind") == "credit_pack"
        CreditPurchase.sync_from_checkout_session!(object)
      else
        Subscription.sync_from_checkout_session!(object)
      end
    when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
      Subscription.sync_from_stripe_subscription!(object)
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end
end
