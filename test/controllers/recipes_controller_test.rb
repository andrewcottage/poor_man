require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login
    @recipe = recipes(:pizza)
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
      post recipes_url, params: {
        recipe: { 
          slug: SecureRandom.uuid,
          tag_names: @recipe.tag_names,
          title: @recipe.title,  
          blurb: @recipe.blurb,
          instructions: Faker::Lorem.paragraph,
          category_id: categories(:one).id,
          image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'),
        } 
      }
    end

    assert_redirected_to recipe_url(Recipe.last.slug)
  end

  test "should show recipe" do
    get recipe_url(@recipe)
    assert_response :success
  end

  test "should get edit" do
    get edit_recipe_url(@recipe)
    assert_response :success
  end

  test "should update recipe" do
    patch recipe_url(@recipe), params: { recipe: { title: SecureRandom.uuid, image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'),          instructions: Faker::Lorem.paragraph,
          content: Faker::Lorem.paragraph, } }
    assert_redirected_to recipe_url(@recipe.slug)
  end

  test "should destroy recipe" do
    assert_difference("Recipe.count", -1) do
      delete recipe_url(@recipe)
    end

    assert_redirected_to recipes_url
  end

  test "should generate ai recipe with valid prompt" do
    login(users(:andrew))
    
    # Mock the OpenAI response
    mock_recipe_data = {
      "title" => "AI Generated Recipe",
      "blurb" => "A delicious test recipe",
      "instructions" => "<p>Test instructions</p>",
      "tags" => ["test", "ai"],
      "difficulty" => 3,
      "prep_time" => 30,
      "cost" => 15.99,
      "category" => "Test Category"
    }
    
    OpenAI::Client.any_instance.stubs(:chat).returns({
      "choices" => [{"message" => {"content" => mock_recipe_data.to_json}}]
    })
    
    post generate_ai_recipe_recipes_path, params: { prompt: "A delicious test recipe" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "AI Generated Recipe", json_response["title"]
    assert_equal "A delicious test recipe", json_response["blurb"]
  end

  test "should not generate ai recipe without prompt" do
    login(users(:andrew))
    
    post generate_ai_recipe_recipes_path, params: { prompt: "" }
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Prompt is required", json_response["error"]
  end
end
