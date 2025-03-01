require "test_helper"

class Recipes::FavoritesControllerTest < ActionDispatch::IntegrationTest

  setup do 
    @user = users(:andrew)
    login
  end

  test "should create favorite" do
    bread = recipes(:bread)
    
    assert_difference('@user.favorites.count') do
      post recipe_favorites_url(bread.slug)
    end
  end

  test "should destroy favorite" do
    favorite = favorites(:andrews_favorite_pizza)

    assert_difference('@user.favorites.count', -1) do
      delete recipe_favorite_url(favorite.recipe.slug, favorite)
    end
  end
end
