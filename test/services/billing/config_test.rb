require "test_helper"

module Billing
  class ConfigTest < ActiveSupport::TestCase
    test "reads stripe values from rails credentials" do
      Rails.application.stubs(:credentials).returns(
        {
          stripe: {
            secret_key: "sk_test_credentials",
            webhook_secret: "whsec_credentials",
            pan_pro_monthly_price_id: "price_monthly_credentials",
            pan_pro_annual_price_id: "price_annual_credentials"
          }
        }
      )

      assert_equal "sk_test_credentials", Config.secret_key
      assert_equal "whsec_credentials", Config.webhook_secret
      assert_equal "price_monthly_credentials", Config.monthly_price_id
      assert_equal "price_annual_credentials", Config.annual_price_id
      assert Config.configured?
    end

    test "falls back to rails secrets when credentials are blank" do
      Rails.application.stubs(:credentials).returns({ stripe: {} })
      Rails.application.stubs(:secrets).returns(
        {
          stripe: {
            secret_key: "sk_test_secrets",
            webhook_secret: "whsec_secrets",
            pan_pro_monthly_price_id: "price_monthly_secrets",
            pan_pro_annual_price_id: "price_annual_secrets"
          }
        }
      )

      assert_equal "sk_test_secrets", Config.secret_key
      assert_equal "whsec_secrets", Config.webhook_secret
      assert_equal "price_monthly_secrets", Config.monthly_price_id
      assert_equal "price_annual_secrets", Config.annual_price_id
    end

    test "falls back to rails secrets when credentials cannot be decrypted" do
      Rails.application.stubs(:credentials).raises(ActiveSupport::MessageEncryptor::InvalidMessage)
      Rails.application.stubs(:secrets).returns(
        {
          stripe: {
            secret_key: "sk_test_secrets",
            webhook_secret: "whsec_secrets",
            pan_pro_monthly_price_id: "price_monthly_secrets",
            pan_pro_annual_price_id: "price_annual_secrets"
          }
        }
      )

      assert_equal "sk_test_secrets", Config.secret_key
      assert_equal "whsec_secrets", Config.webhook_secret
      assert_equal "price_monthly_secrets", Config.monthly_price_id
      assert_equal "price_annual_secrets", Config.annual_price_id
    end
  end
end
