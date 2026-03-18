openai_secret = begin
  Rails.application.credentials.dig(:open_ai, :secret)
rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
  nil
end

OpenAI.configure do |config|
  config.access_token = openai_secret
  config.log_errors = Rails.env.development?
end
