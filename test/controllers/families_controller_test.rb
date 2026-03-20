require "test_helper"

class FamiliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = users(:andrew)
    @victoria = users(:victoria)
    @outsider = users(:user)
    @family = families(:cottages)
  end

  test "index requires login" do
    get families_url
    assert_redirected_to new_session_path
  end

  test "shows families index" do
    login(@andrew)
    get families_url
    assert_response :success
    assert_select "h1", "Your families"
  end

  test "creates a family" do
    login(@andrew)

    assert_difference("Family.count", 1) do
      post families_url, params: { family: { name: "New Family" } }
    end

    family = Family.last
    assert_redirected_to family_path(family)
    assert family.member?(@andrew)
    assert family.family_memberships.find_by(user: @andrew).owner?
  end

  test "shows family to members" do
    login(@victoria)
    get family_url(@family)
    assert_response :success
  end

  test "blocks non-members from show" do
    login(@outsider)
    get family_url(@family)
    assert_redirected_to families_path
  end

  test "owner can update family" do
    login(@andrew)
    patch family_url(@family), params: { family: { name: "Updated Name" } }
    assert_redirected_to family_path(@family)
    assert_equal "Updated Name", @family.reload.name
  end

  test "member cannot update family" do
    login(@victoria)
    patch family_url(@family), params: { family: { name: "Nope" } }
    assert_redirected_to families_path
  end

  test "owner can destroy family" do
    login(@andrew)
    assert_difference("Family.count", -1) do
      delete family_url(@family)
    end
    assert_redirected_to families_path
  end
end
