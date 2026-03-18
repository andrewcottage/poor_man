require "test_helper"

class Admin::RecipeSubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:user)
    @pending_recipe = recipes(:pending_recipe)
  end

  test "admin should get moderation queue" do
    login(@admin)

    get admin_recipe_submissions_url

    assert_response :success
    assert_select "h1", "Recipe Moderation"
    assert_select "h2", text: @pending_recipe.title
  end

  test "admin can approve recipe" do
    login(@admin)

    patch approve_admin_recipe_submission_url(@pending_recipe)

    assert_redirected_to admin_recipe_submissions_path(status: "pending")
    @pending_recipe.reload
    assert @pending_recipe.approved?
    assert_equal @admin, @pending_recipe.reviewed_by
  end

  test "admin can reject recipe" do
    login(@admin)

    patch reject_admin_recipe_submission_url(@pending_recipe), params: { rejection_reason: "Please expand the method." }

    assert_redirected_to admin_recipe_submissions_path(status: "pending")
    @pending_recipe.reload
    assert @pending_recipe.rejected?
    assert_equal "Please expand the method.", @pending_recipe.rejection_reason
  end

  test "non admin cannot access moderation queue" do
    login(@user)

    get admin_recipe_submissions_url

    assert_redirected_to new_session_path
  end
end
