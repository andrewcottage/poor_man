require "test_helper"

class FamilyMembershipTest < ActiveSupport::TestCase
  test "prevents duplicate membership" do
    membership = FamilyMembership.new(family: families(:cottages), user: users(:andrew), role: :member)
    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "is already a member of this family"
  end

  test "allows different users in same family" do
    membership = FamilyMembership.new(family: families(:cottages), user: users(:user), role: :member)
    assert membership.valid?
  end
end
