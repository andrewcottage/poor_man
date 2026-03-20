require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @user = users(:user)
    @token = @user.generate_token_for(:password_reset)
    @default_url_options = { host: "localhost", port: 3000 }
  end

  private

  def default_url_options
    @default_url_options
  end

  public

  test "password_reset email is sent to the correct recipient" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal [ @user.email ], email.to
  end

  test "password_reset email has correct subject" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal "Reset your Stovaro password", email.subject
  end

  test "password_reset email contains reset link" do
    email = UserMailer.password_reset(@user, @token)
    assert_match edit_password_reset_url(@token), email.body.encoded
  end

  test "password_reset email contains expiry notice" do
    email = UserMailer.password_reset(@user, @token)
    assert_match "15 minutes", email.body.encoded
  end

  test "password_reset email is sent from noreply@stovaro.com" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal [ "noreply@stovaro.com" ], email.from
  end
end
