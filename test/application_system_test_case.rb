require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  def sign_in_as(user)
    visit new_session_url

    within("form[action='#{sessions_path}']") do
      fill_in "Email address", with: user.email
      fill_in "Password", with: "password"
      click_button "Sign in"
    end
  end
end
