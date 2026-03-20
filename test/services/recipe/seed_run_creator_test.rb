require "test_helper"

class Recipe::SeedRunCreatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "creates a completed seed run synchronously" do
    stub_seed_preview_generation(title: "Charred Broccoli Pasta", category: "Dinner", tags: [ "vegetarian" ])

    assert_difference("Recipe::Generation.count", 1) do
      generation = Recipe::SeedRunCreator.new(user: @user).call(
        attributes: { prompt: "Create a quick broccoli pasta", servings: 4 },
        auto_publish: false
      )

      assert generation.persisted?
      assert generation.seed_tool?
      assert_equal "Charred Broccoli Pasta", generation.data["title"]
      assert generation.image.attached?
      assert_equal 3, generation.images.count
      assert_not generation.auto_publish_recipe?
    end
  end
end
