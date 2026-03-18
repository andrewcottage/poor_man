google_client_id, google_client_secret = begin
  [
    Rails.application.credentials.dig(:google_oauth, :client_id),
    Rails.application.credentials.dig(:google_oauth, :client_secret)
  ]
rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
  [ nil, nil ]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, google_client_id, google_client_secret if google_client_id.present? && google_client_secret.present?
end

OmniAuth.config.allowed_request_methods = %i[post]
