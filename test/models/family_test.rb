require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @family = Family.new(name: "Test Family", description: "A test family", creator: @user)
  end

  test "should be valid with valid attributes" do
    assert @family.valid?
  end

  test "should require name" do
    @family.name = nil
    assert_not @family.valid?
    assert_includes @family.errors[:name], "can't be blank"
  end

  test "should require creator" do
    @family.creator = nil
    assert_not @family.valid?
  end

  test "should generate slug from name" do
    @family.save
    assert_equal "test-family", @family.slug
  end

  test "should create default cookbook after creation" do
    @family.save
    assert @family.default_cookbook.present?
    assert_equal "Family Recipes", @family.default_cookbook.name
    assert @family.default_cookbook.is_default?
  end

  test "should add creator as member after creation" do
    @family.save
    assert @family.member?(@user)
    assert_includes @family.active_members, @user
  end

  test "creator should be able to manage family" do
    @family.save
    assert @family.can_manage?(@user)
  end

  test "non-creator should not be able to manage family" do
    @family.save
    other_user = users(:two)
    assert_not @family.can_manage?(other_user)
  end
end