require "test_helper"

class TaggingFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:andrew)
    login
    @recipe = recipes(:pizza)
    @tag1 = tags(:one)
    @tag2 = tags(:two)
  end

  test "can add tags to a recipe during creation" do
    tag_names = "#{@tag1.name}, #{@tag2.name}, newtag"
    
    assert_difference("Recipe.count") do
      assert_difference("Tag.count") do # Should create the new tag
        post recipes_url, params: {
          recipe: { 
            slug: SecureRandom.uuid,
            tag_names: tag_names,
            title: "Tagged Recipe",  
            blurb: "A recipe with tags",
            instructions: "Test instructions",
            category_id: categories(:one).id,
            image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'),
          } 
        }
      end
    end
    
    recipe = Recipe.last
    assert_equal 3, recipe.tags.count
    assert recipe.tags.exists?(name: @tag1.name)
    assert recipe.tags.exists?(name: @tag2.name)
    assert recipe.tags.exists?(name: "newtag")
  end
  
  test "can update tags on a recipe" do
    # Start with no tags
    @recipe.taggings.destroy_all
    @recipe.reload
    
    # Add tags
    patch recipe_url(@recipe), params: { 
      recipe: { 
        tag_names: "#{@tag1.name}, newtag2",
        image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'),
        instructions: @recipe.instructions,
      } 
    }
    
    @recipe.reload
    assert_equal 2, @recipe.tags.count
    assert @recipe.tags.exists?(name: @tag1.name)
    assert @recipe.tags.exists?(name: "newtag2")
    
    # Change tags
    patch recipe_url(@recipe), params: { 
      recipe: { 
        tag_names: "#{@tag2.name}, newtag3",
        image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'),
        instructions: @recipe.instructions,
      } 
    }
    
    @recipe.reload
    assert_equal 2, @recipe.tags.count
    assert @recipe.tags.exists?(name: @tag2.name)
    assert @recipe.tags.exists?(name: "newtag3")
  end
  
  test "can browse recipes by tag" do
    # Create a tagging to connect this recipe with the tag
    Tagging.create!(
      tag: @tag1, 
      taggable: @recipe, 
      taggable_type: 'Recipe'
    ) unless Tagging.exists?(tag: @tag1, taggable_id: @recipe.id, taggable_type: 'Recipe')
    
    # Visit recipes page with tag filter
    get recipes_path(q: @tag1.name)
    assert_response :success
    
    # Should show recipes with this tag
    assert_select "div.group.relative h3", text: /#{@recipe.title}/
  end
end 