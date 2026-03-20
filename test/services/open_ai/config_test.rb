require "test_helper"

class OpenAI::ConfigTest < ActiveSupport::TestCase
  test "reads access token from open_ai credentials shape" do
    credentials = { open_ai: { secret: "sk-open-ai" } }

    assert_equal "sk-open-ai", OpenAI::Config.access_token(credentials_provider: credentials, secrets_provider: {})
  end

  test "reads access token from openai secrets shape" do
    secrets = { openai: { secret: "sk-openai" } }

    assert_equal "sk-openai", OpenAI::Config.access_token(credentials_provider: {}, secrets_provider: secrets)
  end

  test "reads image model from either namespace" do
    credentials = { openai: { image_model: "gpt-image-test" } }

    assert_equal "gpt-image-test", OpenAI::Config.image_model(credentials_provider: credentials, secrets_provider: {})
  end
end
