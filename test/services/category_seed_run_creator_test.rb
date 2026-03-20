require "test_helper"

class CategorySeedRunCreatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "creates a completed category seed run synchronously" do
    stub_seed_category_preview

    assert_difference("CategorySeedRun.count", 1) do
      category_seed_run = CategorySeedRunCreator.new(user: @user).call(
        prompt: "Create a weeknight pasta category",
        auto_publish: false
      )

      assert category_seed_run.persisted?
      assert_equal "Weeknight Pasta", category_seed_run.data["title"]
      assert_equal "weeknight-pasta", category_seed_run.data["slug"]
      assert category_seed_run.image.attached?
      assert_not category_seed_run.published_category.present?
    end
  end
end
