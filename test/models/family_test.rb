require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  test "requires name" do
    family = Family.new(created_by: users(:andrew).id)
    assert_not family.valid?
    assert_includes family.errors[:name], "can't be blank"
  end

  test "member? returns true for members" do
    family = families(:cottages)
    assert family.member?(users(:andrew))
    assert family.member?(users(:victoria))
    assert_not family.member?(users(:user))
  end

  test "admin_or_owner? returns true for owner" do
    family = families(:cottages)
    assert family.admin_or_owner?(users(:andrew))
    assert_not family.admin_or_owner?(users(:victoria))
  end

  test "owner returns the owner user" do
    family = families(:cottages)
    assert_equal users(:andrew), family.owner
  end
end
