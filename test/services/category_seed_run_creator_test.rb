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

  test "parses fenced json responses for category previews" do
    stub_seed_category_preview(wrap_in_code_fence: true)

    category_seed_run = CategorySeedRunCreator.new(user: @user).call(
      prompt: "Create a weeknight pasta category",
      auto_publish: false
    )

    assert_equal "Weeknight Pasta", category_seed_run.data["title"]
    assert category_seed_run.complete?
  end

  test "persists a category preview error instead of raising on image failure" do
    stub_openai_category_generation_response(
      title: "Weeknight Pasta",
      slug: "weeknight-pasta",
      description: "Fast, satisfying pasta recipes built for busy evenings."
    )
    stub_request(:post, "#{OpenAITestHelper::OPENAI_API_BASE}/images/generations").to_return(status: 500, body: "boom")

    category_seed_run = CategorySeedRunCreator.new(user: @user).call(
      prompt: "Create a weeknight pasta category",
      auto_publish: false
    )

    assert_match(/Category image generation failed/, category_seed_run.seed_publish_error)
    assert_equal "Weeknight Pasta", category_seed_run.data["title"]
    assert_not category_seed_run.complete?
  end
end
