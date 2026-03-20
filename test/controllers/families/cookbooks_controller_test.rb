require "test_helper"

class Families::CookbooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = users(:andrew)
    @victoria = users(:victoria)
    @outsider = users(:user)
    @family = families(:cottages)
    @cookbook = family_cookbooks(:weeknight_dinners)
  end

  test "member can view cookbook" do
    login(@victoria)
    get family_cookbook_url(@family, @cookbook)
    assert_response :success
  end

  test "non-member cannot view cookbook" do
    login(@outsider)
    get family_cookbook_url(@family, @cookbook)
    assert_redirected_to families_path
  end

  test "member can create cookbook" do
    login(@victoria)

    assert_difference("FamilyCookbook.count", 1) do
      post family_cookbooks_url(@family), params: { family_cookbook: { name: "Desserts" } }
    end

    assert_redirected_to family_cookbook_path(@family, FamilyCookbook.last)
  end

  test "member can update cookbook" do
    login(@victoria)
    patch family_cookbook_url(@family, @cookbook), params: { family_cookbook: { name: "Updated" } }
    assert_redirected_to family_cookbook_path(@family, @cookbook)
    assert_equal "Updated", @cookbook.reload.name
  end

  test "member can destroy cookbook" do
    login(@victoria)
    assert_difference("FamilyCookbook.count", -1) do
      delete family_cookbook_url(@family, @cookbook)
    end
    assert_redirected_to family_path(@family)
  end
end
