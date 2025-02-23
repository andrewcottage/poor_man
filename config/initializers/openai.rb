OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.open_ai.secret
  config.log_errors = Rails.env.development?
end