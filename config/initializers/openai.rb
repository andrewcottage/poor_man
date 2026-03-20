require Rails.root.join("app/services/open_ai/config")

OpenAI.configure do |config|
  config.access_token = OpenAI::Config.access_token
  config.log_errors = Rails.env.development?
end
