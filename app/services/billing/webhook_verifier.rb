require "openssl"

module Billing
  class WebhookVerifier
    DEFAULT_TOLERANCE = 300

    def self.valid?(payload:, signature_header:, secret:, tolerance: DEFAULT_TOLERANCE)
      return false if payload.blank? || signature_header.blank? || secret.blank?

      timestamp, signatures = parse_signature_header(signature_header)
      return false if timestamp.blank? || signatures.blank?
      return false if timestamp.to_i < tolerance.seconds.ago.to_i

      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")

      signatures.any? do |signature|
        ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
      end
    end

    def self.parse_signature_header(signature_header)
      pairs = signature_header.split(",").map { |pair| pair.split("=", 2) }
      timestamp = pairs.find { |key, _value| key == "t" }&.last
      signatures = pairs.filter_map { |key, value| value if key == "v1" }

      [ timestamp, signatures ]
    end
  end
end
