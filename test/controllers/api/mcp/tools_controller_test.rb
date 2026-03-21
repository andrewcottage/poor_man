require "test_helper"

class Api::Mcp::ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @admin = users(:admin)
  end

  # Discovery

  test "GET /api/mcp/tools returns tool list for regular user" do
    get api_mcp_tools_url, headers: bearer_headers(@user)

    assert_response :success

    json = JSON.parse(response.body)
    assert json["instructions"].present?

    tool_names = json["tools"].map { |t| t["name"] }
    assert_equal 8, tool_names.size
    assert_includes tool_names, "get_categories"
    assert_includes tool_names, "search_recipes"
    assert_not_includes tool_names, "preview_seed_recipe"
  end

  test "GET /api/mcp/tools returns admin tools for admin user" do
    get api_mcp_tools_url, headers: bearer_headers(@admin)

    assert_response :success

    json = JSON.parse(response.body)
    tool_names = json["tools"].map { |t| t["name"] }
    assert_equal 18, tool_names.size
    assert_includes tool_names, "get_categories"
    assert_includes tool_names, "preview_seed_recipe"
  end

  test "GET /api/mcp/tools without auth returns 401" do
    get api_mcp_tools_url

    assert_response :unauthorized
  end

  # Execution

  test "POST /api/mcp/tools/get_categories returns category data" do
    post api_mcp_tools_url + "/get_categories",
      headers: bearer_headers(@user),
      env: { "RAW_POST_DATA" => {}.to_json }

    assert_response :success

    json = JSON.parse(response.body)
    assert_not json["isError"]
    assert json["content"].present?
  end

  test "POST /api/mcp/tools/search_recipes with params returns results" do
    post api_mcp_tools_url + "/search_recipes",
      headers: bearer_headers(@user),
      env: { "RAW_POST_DATA" => { query: "pizza" }.to_json }

    assert_response :success

    json = JSON.parse(response.body)
    assert_not json["isError"]
  end

  test "POST /api/mcp/tools/preview_seed_recipe as non-admin returns error" do
    post api_mcp_tools_url + "/preview_seed_recipe",
      headers: bearer_headers(@user),
      env: { "RAW_POST_DATA" => { prompt: "test recipe" }.to_json }

    assert_response :not_found
  end

  test "POST /api/mcp/tools/nonexistent returns 404" do
    post api_mcp_tools_url + "/nonexistent",
      headers: bearer_headers(@user),
      env: { "RAW_POST_DATA" => {}.to_json }

    assert_response :not_found
  end

  private

  def bearer_headers(user)
    { "Authorization" => "Bearer #{user.api_key}" }
  end
end
