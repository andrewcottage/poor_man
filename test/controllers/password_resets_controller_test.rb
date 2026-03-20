require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:user)
  end

  test "GET new renders the email form" do
    get new_password_reset_url
    assert_response :success
    assert_select "h2", text: "Reset your password"
    assert_select "input[type='email']"
  end

  test "POST create with valid email enqueues reset email and renders confirmation" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: @user.email }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end

  test "POST create with unknown email still renders confirmation" do
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: "nobody@example.com" }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end

  test "POST create with OAuth user email does not enqueue email" do
    oauth_user = users(:andrew)
    oauth_user.update_columns(provider: "google_oauth2")

    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: oauth_user.email }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end

  test "GET edit with valid token renders new password form" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_reset_url(token)
    assert_response :success
    assert_select "h2", text: "Set your new password"
    assert_select "input[type='password']", count: 2
  end

  test "GET edit with invalid token redirects to new with alert" do
    get edit_password_reset_url("invalid-token")
    assert_redirected_to new_password_reset_url
    assert_equal "That reset link is invalid or has expired.", flash[:alert]
  end

  test "PATCH update with valid token and matching passwords updates password and signs in" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to root_url
    assert_equal "Your password has been reset.", flash[:notice]
    assert_equal @user.id, session[:user_id]
    assert @user.reload.authenticate("newsecurepassword")
  end

  test "PATCH update with mismatched passwords re-renders form" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "different"
    }
    assert_response :unprocessable_content
    assert_select "h2", text: "Set your new password"
  end

  test "PATCH update with blank password re-renders form" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "",
      password_confirmation: ""
    }
    assert_response :unprocessable_content
    assert_select "h2", text: "Set your new password"
  end

  test "PATCH update with invalid token redirects to new" do
    patch password_reset_url("invalid-token"), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to new_password_reset_url
    assert_equal "That reset link is invalid or has expired.", flash[:alert]
  end

  test "token cannot be reused after successful reset" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to root_url

    # Try to reuse the same token
    get edit_password_reset_url(token)
    assert_redirected_to new_password_reset_url
  end
end
