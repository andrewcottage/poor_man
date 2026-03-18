require "net/http"

module Billing
  class StripeClient
    class Error < StandardError; end

    API_BASE = URI("https://api.stripe.com").freeze

    def create_checkout_session(user:, plan:, success_url:, cancel_url:)
      price_id = Billing::Config.price_id_for(plan)
      raise Error, "Missing Stripe price for #{plan}." if price_id.blank?

      params = {
        "mode" => "subscription",
        "success_url" => success_url,
        "cancel_url" => cancel_url,
        "client_reference_id" => user.id,
        "allow_promotion_codes" => "true",
        "line_items[0][price]" => price_id,
        "line_items[0][quantity]" => "1",
        "metadata[user_id]" => user.id,
        "metadata[plan]" => plan,
        "metadata[price_id]" => price_id,
        "subscription_data[metadata][user_id]" => user.id,
        "subscription_data[metadata][plan]" => plan
      }

      if user.stripe_customer_id.present?
        params["customer"] = user.stripe_customer_id
      else
        params["customer_email"] = user.email
      end

      post_form("/v1/checkout/sessions", params)
    end

    def create_credit_pack_checkout_session(user:, credit_pack:, success_url:, cancel_url:)
      price_id = Billing::Config.credit_pack_price_id(credit_pack.fetch(:id))
      raise Error, "Missing Stripe price for #{credit_pack[:name]}." if price_id.blank?

      params = {
        "mode" => "payment",
        "success_url" => success_url,
        "cancel_url" => cancel_url,
        "client_reference_id" => user.id,
        "allow_promotion_codes" => "true",
        "line_items[0][price]" => price_id,
        "line_items[0][quantity]" => "1",
        "metadata[user_id]" => user.id,
        "metadata[kind]" => "credit_pack",
        "metadata[pack_id]" => credit_pack[:id],
        "metadata[credits]" => credit_pack[:credits],
        "metadata[price_id]" => price_id
      }

      if user.stripe_customer_id.present?
        params["customer"] = user.stripe_customer_id
      else
        params["customer_email"] = user.email
      end

      post_form("/v1/checkout/sessions", params)
    end

    private

    def post_form(path, params)
      request = Net::HTTP::Post.new(path)
      request["Authorization"] = "Bearer #{Billing::Config.secret_key}"
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = URI.encode_www_form(params)

      response = Net::HTTP.start(API_BASE.host, API_BASE.port, use_ssl: true) do |http|
        http.request(request)
      end

      body = JSON.parse(response.body)
      return body if response.is_a?(Net::HTTPSuccess)

      message = body.dig("error", "message") || "Stripe request failed."
      raise Error, message
    rescue JSON::ParserError
      raise Error, "Stripe returned an invalid response."
    end
  end
end
