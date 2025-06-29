require "test_helper"

class FamilyMembershipTest < ActiveSupport::TestCase
  def setup
    @family = families(:one)
    @user = users(:two)
    @membership = FamilyMembership.new(family: @family, user: @user, status: :pending)
  end

  test "should be valid with valid attributes" do
    assert @membership.valid?
  end

  test "should require family" do
    @membership.family = nil
    assert_not @membership.valid?
  end

  test "should require user" do
    @membership.user = nil
    assert_not @membership.valid?
  end

  test "should generate invitation token for pending membership" do
    @membership.save
    assert @membership.invitation_token.present?
    assert @membership.invited_at.present?
  end

  test "should not generate invitation token for accepted membership" do
    @membership.status = :accepted
    @membership.save
    assert_nil @membership.invitation_token
  end

  test "should accept invitation" do
    @membership.save
    @membership.accept!
    assert @membership.accepted?
    assert @membership.accepted_at.present?
  end

  test "should decline invitation" do
    @membership.save
    @membership.decline!
    assert @membership.declined?
  end

  test "should enforce unique family/user combination" do
    @membership.save
    duplicate = FamilyMembership.new(family: @family, user: @user, status: :pending)
    assert_not duplicate.valid?
  end
end