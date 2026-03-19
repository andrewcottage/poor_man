require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:andrew)
    sign_in_as(@admin)
  end

  test "visiting the categories index" do
    visit categories_url
    assert_selector "h1", text: "Food Categories" 
  end
  
  test "viewing a category" do
    visit categories_url
    # Find and click on the first category (using the link around the image and title)
    first(".grid-cols-1.gap-x-6 a.group").click
    
    # Verify we're on a category page by checking for the recipes display
    assert_selector "div#recipes", count: 1
  end
end
