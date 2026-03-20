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

  test "parses fenced json responses from the model" do
    stub_openai_recipe_generation_response(
      title: "Charred Broccoli Pasta",
      blurb: "A quick pasta.",
      ingredients: [ { quantity: "1", unit: "head", name: "broccoli" } ],
      instructions: "<p>Cook it.</p>",
      tags: [ "vegetarian" ],
      difficulty: 2,
      prep_time: 20,
      cost: 12.0,
      servings: 4,
      category: "Dinner",
      wrap_in_code_fence: true
    )
    stub_openai_image_generation_sequence(count: 4, prefix: "charred-broccoli-pasta")

    generation = Recipe::SeedRunCreator.new(user: @user).call(
      attributes: { prompt: "Create a quick broccoli pasta", servings: 4 },
      auto_publish: false
    )

    assert_equal "Charred Broccoli Pasta", generation.data["title"]
    assert generation.complete?
  end

  test "persists a generation error instead of raising on image failure" do
    stub_openai_recipe_generation_response(
      title: "Charred Broccoli Pasta",
      blurb: "A quick pasta.",
      ingredients: [ { quantity: "1", unit: "head", name: "broccoli" } ],
      instructions: "<p>Cook it.</p>",
      tags: [ "vegetarian" ],
      difficulty: 2,
      prep_time: 20,
      cost: 12.0,
      servings: 4,
      category: "Dinner"
    )
    stub_request(:post, "#{OpenAITestHelper::OPENAI_API_BASE}/images/generations").to_return(status: 500, body: "boom")

    generation = Recipe::SeedRunCreator.new(user: @user).call(
      attributes: { prompt: "Create a quick broccoli pasta", servings: 4 },
      auto_publish: false
    )

    assert_match(/Hero image generation failed/, generation.seed_publish_error)
    assert_equal "Charred Broccoli Pasta", generation.data["title"]
    assert_not generation.complete?
  end
end
