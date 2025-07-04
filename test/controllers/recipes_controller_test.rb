require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recipe = recipes(:one)
    @user = users(:one)
    @user.update!(admin: true)
    login(@user)
  end

  test "should get index" do
    get recipes_url
    assert_response :success
  end

  test "should get new" do
    get new_recipe_url
    assert_response :success
  end

  test "should create recipe" do
    assert_difference("Recipe.count") do
      post recipes_url, params: { recipe: { title: "Test Recipe", blurb: "Test blurb", instructions: "Test instructions", slug: "test-recipe", category_id: @recipe.category_id, tag_names: "test" } }
    end

    assert_redirected_to recipe_url(Recipe.last.slug)
  end

  test "should show recipe" do
    get recipe_url(@recipe.slug)
    assert_response :success
  end

  test "should get edit" do
    get edit_recipe_url(@recipe.slug)
    assert_response :success
  end

  test "should update recipe" do
    patch recipe_url(@recipe.slug), params: { recipe: { title: "Updated Title", blurb: @recipe.blurb, instructions: @recipe.instructions, slug: @recipe.slug, category_id: @recipe.category_id, tag_names: @recipe.tag_names } }
    assert_redirected_to recipe_url(@recipe.slug)
    assert_equal "Updated Title", @recipe.reload.title
  end

  test "should destroy recipe" do
    assert_difference("Recipe.count", -1) do
      delete recipe_url(@recipe.slug)
    end

    assert_redirected_to recipes_url
  end

  test "should generate recipe with AI for admin" do
    # Mock the OpenAI response
    Recipe.expects(:generate_from_prompt).with("A delicious pasta dish").returns({
      "title" => "AI Generated Pasta",
      "blurb" => "A delicious pasta dish",
      "instructions" => "<p>Cook pasta according to package instructions</p>",
      "tag_names" => "pasta, italian",
      "cost" => "12.99",
      "difficulty" => 3,
      "prep_time" => 30,
      "slug" => "ai-generated-pasta"
    })

    post generate_with_ai_recipes_url, params: { prompt: "A delicious pasta dish" }
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_equal "AI Generated Pasta", response_data["title"]
    assert_equal "A delicious pasta dish", response_data["blurb"]
  end

  test "should require prompt for AI generation" do
    post generate_with_ai_recipes_url, params: { prompt: "" }
    assert_response :bad_request
    
    response_data = JSON.parse(response.body)
    assert_equal "Prompt is required", response_data["error"]
  end

  test "should require admin for AI generation" do
    @user.update!(admin: false)
    
    post generate_with_ai_recipes_url, params: { prompt: "A delicious pasta dish" }
    assert_response :redirect
  end
end
