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
end
