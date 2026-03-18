require "test_helper"

class Profiles::CollectionRecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @collection = collections(:weeknights)
    login(@user)
  end

  test "adds recipe to collection" do
    assert_difference("CollectionRecipe.count", 1) do
      post profiles_collection_recipes_url, params: {
        collection_id: @collection.id,
        recipe_id: recipes(:bread).id
      }
    end

    assert_redirected_to profiles_collection_path(@collection)
  end

  test "removes recipe from collection" do
    collection_recipe = collection_recipes(:weeknight_pizza)

    assert_difference("CollectionRecipe.count", -1) do
      delete profiles_collection_recipe_url(collection_recipe)
    end

    assert_redirected_to profiles_collection_path(@collection)
  end
end
