require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "#new" do
    get new_registration_url
    assert_response :success
  end

  test "#create" do
    post registrations_url, params: { registration: { email: Faker::Internet.email, password: 'password', password_confirmation: 'password' } }
    assert_response :success
  end
end
