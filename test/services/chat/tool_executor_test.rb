require "test_helper"

class Chat::ToolExecutorTest < ActiveSupport::TestCase
  setup do
    @user = users(:pro_user)
    @executor = Chat::ToolExecutor.new(user: @user)
    @admin = users(:admin)
    @admin_executor = Chat::ToolExecutor.new(user: @admin)
  end

  test "search_recipes returns JSON array" do
    result = JSON.parse(@executor.call(tool_name: "search_recipes", arguments: { "query" => "chicken" }))
    assert_kind_of Array, result
  end

  test "get_categories returns all categories" do
    result = JSON.parse(@executor.call(tool_name: "get_categories", arguments: {}))
    assert_kind_of Array, result
    assert result.all? { |c| c.key?("title") && c.key?("slug") }
  end

  test "get_user_favorites returns user favorites" do
    result = JSON.parse(@executor.call(tool_name: "get_user_favorites", arguments: {}))
    assert_kind_of Array, result
  end

  test "get_user_collections returns user collections" do
    result = JSON.parse(@executor.call(tool_name: "get_user_collections", arguments: {}))
    assert_kind_of Array, result
  end

  test "get_user_recipes returns user recipes" do
    result = JSON.parse(@executor.call(tool_name: "get_user_recipes", arguments: {}))
    assert_kind_of Array, result
  end

  test "get_user_ratings returns user ratings" do
    result = JSON.parse(@executor.call(tool_name: "get_user_ratings", arguments: {}))
    assert_kind_of Array, result
  end

  test "get_trending_recipes returns recipes" do
    result = JSON.parse(@executor.call(tool_name: "get_trending_recipes", arguments: {}))
    assert_kind_of Array, result
  end

  test "get_recipe_details returns error for missing recipe" do
    result = JSON.parse(@executor.call(tool_name: "get_recipe_details", arguments: { "slug" => "nonexistent-recipe" }))
    assert_equal "Recipe not found", result["error"]
  end

  test "unknown tool returns error" do
    result = JSON.parse(@executor.call(tool_name: "unknown_tool", arguments: {}))
    assert result["error"].include?("Unknown tool")
  end

  test "accepts string arguments" do
    result = JSON.parse(@executor.call(tool_name: "get_categories", arguments: "{}"))
    assert_kind_of Array, result
  end

  test "admin can create a seed preview" do
    stub_seed_preview_generation

    result = JSON.parse(@admin_executor.call(
      tool_name: "preview_seed_recipe",
      arguments: { "prompt" => "Create a vegan noodle bowl", "publish_immediately" => false }
    ))

    assert_equal "Roasted Cauliflower Grain Bowl", result["title"]
    assert_equal "ready", result["status"]
    assert_equal 4, result["image_urls"].length
    assert_match %r{/admin/seed_recipes/\d+}, result["preview_url"]
  end

  test "admin can create a category seed preview" do
    stub_seed_category_preview

    result = JSON.parse(@admin_executor.call(
      tool_name: "preview_seed_category",
      arguments: { "prompt" => "Create a weeknight pasta category", "publish_immediately" => false }
    ))

    assert_equal "Weeknight Pasta", result["title"]
    assert_equal "ready", result["status"]
    assert_equal 1, result["image_urls"].length
    assert_match %r{/admin/seed_categories/\d+}, result["preview_url"]
  end

  test "non admin cannot use seed tools" do
    result = JSON.parse(@executor.call(
      tool_name: "preview_seed_recipe",
      arguments: { "prompt" => "Create a vegan noodle bowl" }
    ))

    assert_equal "This tool is only available to admins.", result["error"]
  end

  test "admin can publish a completed seed preview" do
    stub_openai_image_generation_sequence(count: 1, prefix: "grain-bowls-category")

    generation = recipe_generations(:processing)
    generation.update!(
      user: @admin,
      seed_tool: true,
      data: {
        "title" => "Roasted Cauliflower Grain Bowl",
        "blurb" => "A hearty bowl with roasted vegetables and tahini dressing.",
        "ingredients" => [
          { "quantity" => "1", "unit" => "head", "name" => "cauliflower" }
        ],
        "instructions" => "<p>Roast the cauliflower.</p>",
        "tags" => [ "vegetarian" ],
        "difficulty" => 2,
        "prep_time" => 35,
        "cost" => 14.5,
        "servings" => 4,
        "category" => "Grain Bowls"
      }
    )
    generation.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "main.jpeg",
      content_type: "image/jpeg"
    )
    generation.images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "gallery.jpeg",
      content_type: "image/jpeg"
    )

    result = JSON.parse(@admin_executor.call(
      tool_name: "publish_seed_recipe",
      arguments: { "generation_id" => generation.id }
    ))

    assert result["published"]
    assert_equal "/recipes/roasted-cauliflower-grain-bowl", result.dig("recipe", "url")
  end

  test "admin can publish a completed category seed preview" do
    category_seed_run = category_seed_runs(:one)
    category_seed_run.update!(user: @admin)
    category_seed_run.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "weeknight-pasta.jpg",
      content_type: "image/jpeg"
    )

    result = JSON.parse(@admin_executor.call(
      tool_name: "publish_seed_category",
      arguments: { "category_seed_run_id" => category_seed_run.id }
    ))

    assert result["published"]
    assert_equal "/categories/weeknight-pasta", result.dig("category_record", "url")
  end
end
