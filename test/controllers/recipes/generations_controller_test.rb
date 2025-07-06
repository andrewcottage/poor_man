require "test_helper"

class Recipes::GenerationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:user)
    @generation = recipe_generations(:one)
  end

  test "should get index when logged in" do
    sign_in @user
    get recipes_generations_url
    assert_response :success
    assert_select "h1", "Recipe Generations"
  end

  test "should redirect to login when not logged in" do
    get recipes_generations_url
    assert_redirected_to new_session_path
  end

  test "should show generation when logged in" do
    sign_in @user
    get recipes_generation_url(@generation)
    assert_response :success
    assert_select "h1", @generation.prompt
  end

  test "should redirect to login when trying to show generation without login" do
    get recipes_generation_url(@generation)
    assert_redirected_to new_session_path
  end

  test "should get new when admin" do
    sign_in @admin
    get new_recipes_generation_url
    assert_response :success
    assert_select "h1", "Generate New Recipe"
  end

  test "should redirect to login when non-admin tries to access new" do
    sign_in @user
    get new_recipes_generation_url
    assert_redirected_to new_session_path
  end

  test "should create generation when admin" do
    sign_in @admin
    
    assert_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Test recipe generation" } }
    end

    assert_redirected_to recipes_generation_url(Recipe::Generation.last)
    assert_equal "Recipe Generation is in progress.", flash[:notice]
  end

  test "should not create generation when not admin" do
    sign_in @user
    
    assert_no_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Test recipe generation" } }
    end

    assert_redirected_to new_session_path
  end

  test "should get edit when admin" do
    sign_in @admin
    get edit_recipes_generation_url(@generation)
    assert_response :success
    assert_select "h1", "Edit Recipe Generation"
  end

  test "should redirect to login when non-admin tries to edit" do
    sign_in @user
    get edit_recipes_generation_url(@generation)
    assert_redirected_to new_session_path
  end

  test "should update generation when admin" do
    sign_in @admin
    patch recipes_generation_url(@generation), params: { recipe_generation: { prompt: "Updated prompt" } }
    assert_redirected_to recipes_generation_url(@generation)
    assert_equal "Recipe Generation was successfully updated.", flash[:notice]
    @generation.reload
    assert_equal "Updated prompt", @generation.prompt
  end

  test "should not update generation when not admin" do
    sign_in @user
    patch recipes_generation_url(@generation), params: { recipe_generation: { prompt: "Updated prompt" } }
    assert_redirected_to new_session_path
  end

  test "should destroy generation when admin" do
    sign_in @admin
    
    assert_difference("Recipe::Generation.count", -1) do
      delete recipes_generation_url(@generation)
    end

    assert_redirected_to recipes_generations_url
    assert_equal "Recipe Generation was successfully deleted.", flash[:notice]
  end

  test "should not destroy generation when not admin" do
    sign_in @user
    
    assert_no_difference("Recipe::Generation.count") do
      delete recipes_generation_url(@generation)
    end

    assert_redirected_to new_session_path
  end

  test "should search generations" do
    sign_in @user
    get recipes_generations_url, params: { q: "test" }
    assert_response :success
  end

  test "should return json for show" do
    sign_in @user
    get recipes_generation_url(@generation, format: :json)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @generation.id, json_response["id"]
    assert_equal @generation.prompt, json_response["prompt"]
    assert_includes json_response.keys, "complete"
  end

  test "should handle invalid generation creation" do
    sign_in @admin
    
    assert_no_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "should handle invalid generation update" do
    sign_in @admin
    
    patch recipes_generation_url(@generation), params: { recipe_generation: { prompt: "" } }
    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end



  private

  def sign_in(user)
    post sessions_url, params: { session: { email: user.email, password: "password" } }
  end
end 