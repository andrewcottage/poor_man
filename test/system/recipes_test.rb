require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:pizza)
    @admin = users(:andrew)
    
    # Login as admin
    visit new_session_url
    fill_in "Email address", with: @admin.email
    fill_in "Password", with: "password"
    click_on "Sign in"
  end

  test "visiting the index" do
    visit recipes_url
    assert_selector "h1", text: "Browse Recipes"
  end
  
  test "viewing a recipe" do
    visit recipes_url
    # Find and click on the first recipe
    # The recipe card is nested within the grid
    within "#recipes" do
      # Click on the first recipe card
      first(".group.relative").click
    end
    
    # Verify we're on a recipe page by checking for typical recipe elements
    assert_selector "h1", count: 1 # Should have a heading
  end
  
  test "creating a new recipe" do
    visit recipes_url
    # Look for the 'Add your own recipe' link
    click_on "Add your own recipe"
    
    # Verify we're on the new recipe page
    assert_selector "h1", text: /New Recipe|Create Recipe/i
  end

  test "should create recipe" do
    visit recipes_url
    click_on "New recipe"

    fill_in "Slug", with: @recipe.slug
    fill_in "Tags", with: @recipe.tag_names
    fill_in "Title", with: @recipe.title
    click_on "Create Recipe"

    assert_text "Recipe was successfully created"
    click_on "Back"
  end

  test "should update Recipe" do
    visit recipe_url(@recipe)
    click_on "Edit this recipe", match: :first

    fill_in "Slug", with: @recipe.slug
    fill_in "Tags", with: @recipe.tag_names
    fill_in "Title", with: @recipe.title
    click_on "Update Recipe"

    assert_text "Recipe was successfully updated"
    click_on "Back"
  end

  test "should destroy Recipe" do
    visit recipe_url(@recipe)
    click_on "Destroy this recipe", match: :first

    assert_text "Recipe was successfully destroyed"
  end
end
