require "test_helper"

class Recipes::FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @recipe = recipes(:bread)
  end

  test "creates favorite within free limit" do
    login(@user)

    assert_difference("Favorite.count", 1) do
      post recipe_favorites_url(@recipe)
    end

    assert_redirected_to recipe_path(@recipe.slug)
  end

  test "redirects to pricing when favorite limit is reached" do
    login(@user)
    User.any_instance.stubs(:can_add_favorite?).returns(false)

    assert_no_difference("Favorite.count") do
      post recipe_favorites_url(@recipe)
    end

    assert_redirected_to pricing_path
  end
end
