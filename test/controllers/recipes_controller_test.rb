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

  test "should get new with generation prefill" do
    generation = recipe_generations(:one)
    get new_recipe_url(generation_id: generation.id)
    assert_response :success
    
    # Check that the form is prefilled with generation data
    assert_select "input[value='#{generation.data['title']}']"
    assert_select "textarea", text: generation.data['blurb']
    # Check that generation_id is included as hidden field
    assert_select "input[name='recipe[generation_id]'][value='#{generation.id}']"
    # Check that regular image upload fields are hidden
    assert_select "input[type='file'][name='recipe[image]']", count: 0
  end

  test "should get new without generation prefill" do
    get new_recipe_url
    assert_response :success
    
    # Should not show the prefill notification
    assert_select ".bg-blue-50", count: 0
  end

  test "should ignore invalid generation_id" do
    get new_recipe_url(generation_id: 999999)
    assert_response :success
    
    # Should not show the prefill notification
    assert_select ".bg-blue-50", count: 0
  end

  test "should ignore generation without data" do
    processing_generation = recipe_generations(:processing)
    get new_recipe_url(generation_id: processing_generation.id)
    assert_response :success
    
    # Should not show the prefill notification
    assert_select ".bg-blue-50", count: 0
  end

  test "should create recipe from generation data" do
    generation = recipe_generations(:one)
    
    assert_difference("Recipe.count") do
      post recipes_url, params: {
        recipe: {
          generation_id: generation.id,
          slug: SecureRandom.uuid,
          tag_names: generation.data['tags'].join(', '),
          title: generation.data['title'],
          blurb: generation.data['blurb'],
          instructions: generation.data['instructions'],
          category_id: categories(:one).id,
          difficulty: generation.data['difficulty'],
          prep_time: generation.data['prep_time'],
          cost: generation.data['cost'],
          image: fixture_file_upload('vaporwave.jpeg', 'image/jpg')
        }
      }
    end
    
    recipe = Recipe.last
    assert_redirected_to recipe_url(recipe.slug)
    
    # Check that recipe has the correct data from generation
    assert_equal generation.data['title'], recipe.title
    assert_equal generation.data['blurb'], recipe.blurb
    assert_equal generation.data['difficulty'], recipe.difficulty
    assert_equal generation.data['prep_time'], recipe.prep_time
  end
end
