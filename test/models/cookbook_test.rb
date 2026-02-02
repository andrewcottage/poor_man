require "test_helper"

class CookbookTest < ActiveSupport::TestCase
  def setup
    @family = families(:one)
    @cookbook = Cookbook.new(name: "Test Cookbook", description: "A test cookbook", family: @family)
  end

  test "should be valid with valid attributes" do
    assert @cookbook.valid?
  end

  test "should require name" do
    @cookbook.name = nil
    assert_not @cookbook.valid?
    assert_includes @cookbook.errors[:name], "can't be blank"
  end

  test "should require family" do
    @cookbook.family = nil
    assert_not @cookbook.valid?
  end

  test "should generate slug from name" do
    @cookbook.save
    assert_equal "test-cookbook", @cookbook.slug
  end

  test "should be accessible by family members" do
    user = users(:one)
    @family.active_memberships.create!(user: user, status: :accepted, accepted_at: Time.current)
    assert @cookbook.accessible_by?(user)
  end

  test "should not be accessible by non-family members" do
    user = users(:two)
    assert_not @cookbook.accessible_by?(user)
  end

  test "should be editable by family members" do
    user = users(:one)
    @family.active_memberships.create!(user: user, status: :accepted, accepted_at: Time.current)
    assert @cookbook.editable_by?(user)
  end

  test "should be manageable by family creator" do
    assert @cookbook.can_manage?(@family.creator)
  end
end