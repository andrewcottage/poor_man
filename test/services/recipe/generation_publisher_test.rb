require "test_helper"

class Recipe::GenerationPublisherTest < ActiveSupport::TestCase
  setup do
    @generation = recipe_generations(:processing)
    @generation.update!(
      user: users(:admin),
      seed_tool: true,
      data: {
        "title" => "Roasted Cauliflower Grain Bowl",
        "blurb" => "A hearty bowl with roasted vegetables and tahini dressing.",
        "ingredients" => [
          { "quantity" => "1", "unit" => "head", "name" => "cauliflower" },
          { "quantity" => "1", "unit" => "cup", "name" => "farro" }
        ],
        "instructions" => "<p>Roast the cauliflower.</p><p>Cook the farro.</p>",
        "tags" => [ "vegetarian", "grain bowl" ],
        "difficulty" => 2,
        "prep_time" => 35,
        "cost" => 14.5,
        "servings" => 4,
        "category" => "Grain Bowls"
      }
    )
    attach_generation_images(@generation)
  end

  test "publishes a completed seed run and creates a missing category" do
    stub_openai_image_generation_sequence(count: 1, prefix: "grain-bowls-category")

    assert_difference("Category.count", 1) do
      assert_difference("Recipe.count", 1) do
        recipe = Recipe::GenerationPublisher.new(@generation).call

        assert recipe.persisted?
        assert recipe.approved?
        assert_equal "Grain Bowls", recipe.category.title
        assert recipe.image.attached?
        assert_equal 2, recipe.images.count
        assert_equal recipe, @generation.reload.published_recipe
      end
    end
  end

  private

  def attach_generation_images(generation)
    generation.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "preview-main.jpeg",
      content_type: "image/jpeg"
    )

    2.times do |index|
      generation.images.attach(
        io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
        filename: "preview-#{index}.jpeg",
        content_type: "image/jpeg"
      )
    end
  end
end
