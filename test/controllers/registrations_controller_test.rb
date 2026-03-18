require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "#new" do
    get new_registration_url
    assert_response :success
  end

  test "#create" do
    assert_difference("User.count", 1) do
      post registrations_url, params: { registration: { email: Faker::Internet.email, password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to root_path
  end
end
