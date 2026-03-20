# frozen_string_literal: true

module OpenAI
  module Config
    class MissingConfigurationError < StandardError; end

    module_function

    def access_token(credentials_provider: default_credentials_provider, secrets_provider: default_secrets_provider)
      fetch(:secret, credentials_provider:, secrets_provider:)
    end

    def image_model(credentials_provider: default_credentials_provider, secrets_provider: default_secrets_provider)
      fetch(:image_model, credentials_provider:, secrets_provider:)
    end

    def configured?(credentials_provider: default_credentials_provider, secrets_provider: default_secrets_provider)
      access_token(credentials_provider:, secrets_provider:).present?
    end

    def ensure_configured!(credentials_provider: default_credentials_provider, secrets_provider: default_secrets_provider)
      return if configured?(credentials_provider:, secrets_provider:)

      raise MissingConfigurationError,
        "OpenAI is not configured. Add open_ai.secret or openai.secret to Rails credentials or secrets."
    end

    def fetch(key, credentials_provider: default_credentials_provider, secrets_provider: default_secrets_provider)
      [
        dig(credentials_provider, :open_ai, key),
        dig(credentials_provider, :openai, key),
        dig(secrets_provider, :open_ai, key),
        dig(secrets_provider, :openai, key),
        global_value(key)
      ].compact.map(&:to_s).find(&:present?).to_s
    end

    def dig(provider, namespace, key)
      return nil unless provider.respond_to?(:dig)

      provider.dig(namespace, key)
    rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def default_credentials_provider
      Rails.application.credentials
    end

    def default_secrets_provider
      Rails.application.respond_to?(:secrets) ? Rails.application.secrets : nil
    end

    def global_value(key)
      return nil unless OpenAI.respond_to?(:configuration)
      return nil unless OpenAI.configuration.respond_to?(key)

      OpenAI.configuration.public_send(key)
    end
  end
end
