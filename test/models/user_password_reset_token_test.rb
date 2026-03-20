require "test_helper"

class UserPasswordResetTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
  end

  test "generates a password reset token" do
    token = @user.generate_token_for(:password_reset)
    assert_not_nil token
    assert_kind_of String, token
  end

  test "resolves user from valid token" do
    token = @user.generate_token_for(:password_reset)
    resolved = User.find_by_token_for(:password_reset, token)
    assert_equal @user, resolved
  end

  test "returns nil for invalid token" do
    resolved = User.find_by_token_for(:password_reset, "bogus-token")
    assert_nil resolved
  end

  test "token is invalidated after password change" do
    token = @user.generate_token_for(:password_reset)
    @user.update!(password: "newpassword123", password_confirmation: "newpassword123")
    resolved = User.find_by_token_for(:password_reset, token)
    assert_nil resolved
  end

  test "token expires after 15 minutes" do
    token = @user.generate_token_for(:password_reset)
    travel 16.minutes do
      resolved = User.find_by_token_for(:password_reset, token)
      assert_nil resolved
    end
  end

  test "rejects password shorter than 6 characters" do
    @user.password = "short"
    @user.password_confirmation = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 6 characters)"
  end
end
