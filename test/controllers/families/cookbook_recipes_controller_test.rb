require "test_helper"

class Families::CookbookRecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = users(:andrew)
    @outsider = users(:user)
    @family = families(:cottages)
    @cookbook = family_cookbooks(:weeknight_dinners)
    @recipe = recipes(:pizza)
  end

  test "member can add recipe to cookbook" do
    login(@andrew)

    assert_difference("FamilyCookbookRecipe.count", 1) do
      post family_cookbook_cookbook_recipes_url(@family, @cookbook), params: { recipe_id: @recipe.id }
    end

    assert_redirected_to family_cookbook_path(@family, @cookbook)
  end

  test "adding duplicate recipe shows error" do
    login(@andrew)

    FamilyCookbookRecipe.create!(family_cookbook: @cookbook, recipe: @recipe, added_by: @andrew.id)

    assert_no_difference("FamilyCookbookRecipe.count") do
      post family_cookbook_cookbook_recipes_url(@family, @cookbook), params: { recipe_id: @recipe.id }
    end

    assert_redirected_to family_cookbook_path(@family, @cookbook)
  end

  test "member can remove recipe from cookbook" do
    login(@andrew)
    cookbook_recipe = FamilyCookbookRecipe.create!(family_cookbook: @cookbook, recipe: @recipe, added_by: @andrew.id)

    assert_difference("FamilyCookbookRecipe.count", -1) do
      delete family_cookbook_cookbook_recipe_url(@family, @cookbook, cookbook_recipe)
    end
  end

  test "non-member cannot add recipe" do
    login(@outsider)

    assert_no_difference("FamilyCookbookRecipe.count") do
      post family_cookbook_cookbook_recipes_url(@family, @cookbook), params: { recipe_id: @recipe.id }
    end

    assert_redirected_to families_path
  end
end
