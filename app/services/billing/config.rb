module Billing
  class Config
    class << self
      def configured?
        secret_key.present? && monthly_price_id.present? && annual_price_id.present?
      end

      def secret_key
        fetch(:secret_key)
      end

      def webhook_secret
        fetch(:webhook_secret)
      end

      def monthly_price_id
        fetch(:pan_pro_monthly_price_id)
      end

      def annual_price_id
        fetch(:pan_pro_annual_price_id)
      end

      def price_id_for(plan)
        case plan
        when User::PLAN_PRO_MONTHLY
          monthly_price_id
        when User::PLAN_PRO_ANNUAL
          annual_price_id
        end
      end

      def credit_pack_price_id(pack_id)
        case pack_id
        when "extra_5"
          fetch(:credit_pack_extra_5_price_id)
        when "extra_15"
          fetch(:credit_pack_extra_15_price_id)
        end
      end

      def credit_pack_configured?(pack_id)
        secret_key.present? && credit_pack_price_id(pack_id).present?
      end

      def plan_from_price_id(price_id)
        return User::PLAN_PRO_MONTHLY if price_id.present? && price_id == monthly_price_id
        User::PLAN_PRO_ANNUAL if price_id.present? && price_id == annual_price_id
      end

      private

      def fetch(key)
        credential_value(key).presence || secret_value(key).to_s
      end

      def credential_value(key)
        Rails.application.credentials.dig(:stripe, key).to_s
      rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
        ""
      end

      def secret_value(key)
        secrets = Rails.application.respond_to?(:secrets) ? Rails.application.secrets : nil
        return "" unless secrets.respond_to?(:dig)

        secrets.dig(:stripe, key).to_s
      end
    end
  end
end
