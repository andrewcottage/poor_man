require "test_helper"

class Recipe::SeedRunCreatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "creates a completed seed run synchronously" do
    Recipe::Generation.any_instance.expects(:generate_recipe).once do |generation|
      generation.update!(
        data: {
          "title" => "Charred Broccoli Pasta",
          "blurb" => "Weeknight pasta with charred broccoli and lemon.",
          "ingredients" => [
            { "quantity" => "12", "unit" => "oz", "name" => "pasta" }
          ],
          "instructions" => "<p>Cook the pasta.</p>",
          "tags" => [ "vegetarian" ],
          "difficulty" => 1,
          "prep_time" => 20,
          "cost" => 11,
          "servings" => 4,
          "category" => "Dinner"
        }
      )
    end
    Recipe::Generation.any_instance.expects(:generate_image).once do |generation|
      generation.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
        filename: "main.jpeg",
        content_type: "image/jpeg"
      )
    end
    Recipe::Generation.any_instance.expects(:generate_images).once do |generation|
      generation.images.attach(
        io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
        filename: "gallery.jpeg",
        content_type: "image/jpeg"
      )
    end

    assert_difference("Recipe::Generation.count", 1) do
      generation = Recipe::SeedRunCreator.new(user: @user).call(
        attributes: { prompt: "Create a quick broccoli pasta", servings: 4 },
        auto_publish: false
      )

      assert generation.persisted?
      assert generation.seed_tool?
      assert_not generation.auto_publish_recipe?
    end
  end
end
