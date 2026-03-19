require "test_helper"

class Chat::ToolExecutorTest < ActiveSupport::TestCase
  setup do
    @user = users(:pro_user)
    @executor = Chat::ToolExecutor.new(user: @user)
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
end
