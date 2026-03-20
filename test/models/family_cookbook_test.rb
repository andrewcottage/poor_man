require "test_helper"

class FamilyCookbookTest < ActiveSupport::TestCase
  test "requires name" do
    cookbook = FamilyCookbook.new(family: families(:cottages), created_by: users(:andrew).id)
    assert_not cookbook.valid?
    assert_includes cookbook.errors[:name], "can't be blank"
  end

  test "name must be unique within family" do
    cookbook = FamilyCookbook.new(
      family: families(:cottages),
      name: family_cookbooks(:weeknight_dinners).name,
      created_by: users(:andrew).id
    )
    assert_not cookbook.valid?
    assert_includes cookbook.errors[:name], "has already been taken"
  end
end
