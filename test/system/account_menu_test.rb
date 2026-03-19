require "application_system_test_case"

class AccountMenuTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    sign_in_as(@user)
  end

  test "opens and closes the desktop account menu" do
    visit root_url

    find("[data-controller='account-dropdown'] [data-account-dropdown-target='button']").click

    assert_selector "[data-controller='account-dropdown'] [data-account-dropdown-target='menu']:not(.hidden)"
    assert_link "Profile", href: profile_path(@user)

    find("body").click

    assert_no_selector "[data-controller='account-dropdown'] [data-account-dropdown-target='menu']:not(.hidden)"
  end
end
