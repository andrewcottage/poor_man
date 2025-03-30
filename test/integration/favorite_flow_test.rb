require "test_helper"

class FavoriteFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:andrew)
    @recipe = recipes(:pizza)
    login
  end

  test "can favorite a recipe" do
    # Ensure the recipe is not already favorited
    @user.favorites.where(recipe: @recipe).destroy_all
    
    # Go to the recipe page
    get recipe_path(@recipe)
    assert_response :success
    
    # Add to favorites
    assert_difference('Favorite.count') do
      post recipe_favorites_path(@recipe)
    end
    
    # Verify the recipe is now in favorites
    get profiles_favorites_path
    assert_response :success
    
    # The recipe card doesn't have a specific class, but we can look for the recipe title
    # inside a div with class group relative
    assert_select "div.group.relative h3", text: /#{@recipe.title}/
  end
  
  test "can unfavorite a recipe" do
    # Ensure the recipe is favorited
    @user.favorites.find_or_create_by(recipe: @recipe)
    
    # Go to the recipe page
    get recipe_path(@recipe)
    assert_response :success
    
    # Remove from favorites
    assert_difference('Favorite.count', -1) do
      delete recipe_favorite_path(@recipe, @user.favorites.find_by(recipe: @recipe))
    end
    
    # Verify the recipe is no longer in favorites
    get profiles_favorites_path
    assert_response :success
    assert_select "div.group.relative h3", text: /#{@recipe.title}/, count: 0
  end
end 