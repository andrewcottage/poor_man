require "test_helper"

class Cooks::FollowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @cook = users(:andrew)
    login(@user)
  end

  test "creates follow relationship" do
    assert_difference("UserFollow.count", 1) do
      post cook_follow_url(@cook.username)
    end

    assert_redirected_to cook_path(@cook.username)
    assert @user.reload.follows?(@cook)
  end

  test "destroys follow relationship" do
    @user.active_follows.create!(followed: @cook)

    assert_difference("UserFollow.count", -1) do
      delete cook_follow_url(@cook.username)
    end

    assert_redirected_to cook_path(@cook.username)
    assert_not @user.reload.follows?(@cook)
  end
end
