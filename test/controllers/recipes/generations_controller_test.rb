require "test_helper"

class Recipes::GenerationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:user)
    @pro_user = users(:pro_user)
    @admin_generation = recipe_generations(:one)
    @user_generation = recipe_generations(:user_owned)
  end

  test "should get index when logged in" do
    sign_in @user

    get recipes_generations_url

    assert_response :success
    assert_select "h1", "Recipe Generations"
    assert_select "h3", text: @user_generation.prompt
    assert_select "h3", text: @admin_generation.prompt, count: 0
  end

  test "should redirect to login when not logged in" do
    get recipes_generations_url

    assert_redirected_to new_session_path
  end

  test "should show own generation when logged in" do
    sign_in @user

    get recipes_generation_url(@user_generation)

    assert_response :success
    assert_select "h1", @user_generation.prompt
  end

  test "should redirect when viewing another users generation" do
    sign_in @user

    get recipes_generation_url(@admin_generation)

    assert_redirected_to recipes_generations_path
  end

  test "should let free user open new generation page" do
    sign_in @user

    get new_recipes_generation_url

    assert_response :success
    assert_select "h1", "Generate New Recipe"
  end

  test "should create generation for free user trial" do
    sign_in @user

    assert_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Test recipe generation" } }
    end

    assert_redirected_to recipes_generation_url(Recipe::Generation.last)
    assert_equal "Recipe Generation is in progress.", flash[:notice]
    @user.reload
    assert_not_nil @user.free_generation_used_at
    assert_equal 1, @user.generations_count
  end

  test "should block free user once trial is used" do
    @user.update!(free_generation_used_at: Time.current, generations_count: 1)
    sign_in @user

    assert_no_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Another prompt" } }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation", text: /free AI generation trial/
  end

  test "should create generation for pro user with monthly quota" do
    sign_in @pro_user

    assert_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Stovaro Pro recipe generation" } }
    end

    assert_redirected_to recipes_generation_url(Recipe::Generation.last)
    @pro_user.reload
    assert_equal 5, @pro_user.generations_count
  end

  test "should block pro user after monthly quota is exhausted" do
    @pro_user.update!(generations_count: 15, generations_reset_at: 2.weeks.from_now)
    sign_in @pro_user

    assert_no_difference("Recipe::Generation.count") do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Blocked pro prompt" } }
    end

    assert_response :unprocessable_entity
    assert_select "div#error_explanation", text: /15 Stovaro Pro generations/
  end

  test "free user can create generation with credit pack balance" do
    @user.update!(free_generation_used_at: Time.current, generations_count: 1, generation_credits_balance: 2)
    sign_in @user

    assert_difference("Recipe::Generation.count", 1) do
      post recipes_generations_url, params: { recipe_generation: { prompt: "Use a paid credit", dietary_preference: "vegan", servings: 3 } }
    end

    assert_redirected_to recipes_generation_url(Recipe::Generation.last)
    assert_equal "vegan", Recipe::Generation.last.dietary_preference
    assert_equal 3, Recipe::Generation.last.servings
    @user.reload
    assert_equal 1, @user.generation_credits_balance
  end

  test "admin can view any generation" do
    sign_in @admin

    get recipes_generation_url(@user_generation)

    assert_response :success
  end

  test "owner can edit generation" do
    sign_in @user

    get edit_recipes_generation_url(@user_generation)

    assert_response :success
  end

  test "non owner cannot edit generation" do
    sign_in @user

    get edit_recipes_generation_url(@admin_generation)

    assert_redirected_to recipes_generations_path
  end

  test "owner can update generation" do
    sign_in @user

    patch recipes_generation_url(@user_generation), params: { recipe_generation: { prompt: "Updated prompt" } }

    assert_redirected_to recipes_generation_url(@user_generation)
    @user_generation.reload
    assert_equal "Updated prompt", @user_generation.prompt
  end

  test "owner can destroy generation" do
    sign_in @user

    assert_difference("Recipe::Generation.count", -1) do
      delete recipes_generation_url(@user_generation)
    end

    assert_redirected_to recipes_generations_url
  end

  test "should return json for show" do
    sign_in @user

    get recipes_generation_url(@user_generation, format: :json)

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @user_generation.id, json_response["id"]
    assert_equal @user_generation.prompt, json_response["prompt"]
    assert_includes json_response.keys, "complete"
  end

  test "owner can regenerate instructions" do
    @user.update!(free_generation_used_at: Time.current, generations_count: 1, generation_credits_balance: 1)
    sign_in @user
    Recipe::Generation.any_instance.expects(:regenerate_instructions_later).once

    post regenerate_instructions_recipes_generation_url(@user_generation)

    assert_redirected_to recipes_generation_url(@user_generation)
    @user.reload
    assert_equal 0, @user.generation_credits_balance
  end

  private

  def sign_in(user)
    post sessions_url, params: { session: { email: user.email, password: "password" } }
  end
end
