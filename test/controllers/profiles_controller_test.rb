require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do 
    @user = users(:andrew)
    login
  end

  test "should get show" do
    get profile_url(@user)
    assert_response :success
    assert_select "a[href='#{pricing_path}']"
    assert_select "a[href='#{profiles_collections_path}']"
  end

  test "profile shows credit balance and recent purchases" do
    @user.update!(generation_credits_balance: 5)
    @user.credit_purchases.create!(pack_id: "extra_5", credits: 5, status: :paid, credited_at: Time.current)

    get profile_url(@user)

    assert_response :success
    assert_select "p", text: "Credit Balance"
    assert_select "p", text: /5 extra generations/
    assert_select "p", text: "Recent Credit Purchases"
  end

  test "pro user sees planner entry point on profile" do
    login(users(:pro_user))

    get profile_url(users(:pro_user))

    assert_response :success
    assert_select "a[href='#{profiles_meal_plan_path}']"
  end

  test "should get edit" do
    get edit_profile_url(@user)
    assert_response :success
  end
end
