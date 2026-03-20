require "test_helper"

class Families::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = users(:andrew)
    @victoria = users(:victoria)
    @outsider = users(:user)
    @family = families(:cottages)
  end

  test "owner can add member by email" do
    login(@andrew)

    assert_difference("FamilyMembership.count", 1) do
      post family_memberships_url(@family), params: { email: @outsider.email }
    end

    assert_redirected_to family_path(@family)
    assert @family.member?(@outsider)
  end

  test "adding non-existent email shows error" do
    login(@andrew)

    assert_no_difference("FamilyMembership.count") do
      post family_memberships_url(@family), params: { email: "nobody@example.com" }
    end

    assert_redirected_to family_path(@family)
    assert_equal "No user found with that email.", flash[:alert]
  end

  test "member cannot add members" do
    login(@victoria)

    assert_no_difference("FamilyMembership.count") do
      post family_memberships_url(@family), params: { email: @outsider.email }
    end

    assert_redirected_to family_path(@family)
  end

  test "owner can remove non-owner member" do
    login(@andrew)
    membership = family_memberships(:victoria_member)

    assert_difference("FamilyMembership.count", -1) do
      delete family_membership_url(@family, membership)
    end
  end

  test "owner cannot be removed" do
    login(@andrew)
    membership = family_memberships(:andrew_owner)

    assert_no_difference("FamilyMembership.count") do
      delete family_membership_url(@family, membership)
    end
  end

  test "member can leave family" do
    login(@victoria)
    membership = family_memberships(:victoria_member)

    assert_difference("FamilyMembership.count", -1) do
      delete family_membership_url(@family, membership)
    end

    assert_redirected_to families_path
  end
end
