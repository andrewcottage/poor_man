require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:andrew)
    @user = users(:user)
    @recipe = recipes(:pizza)
    @pending_recipe = recipes(:pending_recipe)
  end

  test "should get index with approved recipes only" do
    get recipes_url

    assert_response :success
    assert_select "h3", text: @recipe.title
    assert_select "h3", text: @pending_recipe.title, count: 0
  end

  test "index supports discovery filters" do
    @recipe.update_columns(difficulty: 1, prep_time: 20, cost_cents: 1200)
    recipes(:bread).update_columns(difficulty: 4, prep_time: 75, cost_cents: 2800)
    Tagging.create!(taggable: @recipe, tag: Tag.find_or_create_by!(name: "vegan"))

    get recipes_url, params: { difficulty: "1", prep_time: "30", cost: "15", dietary_tags: [ "vegan" ] }

    assert_response :success
    assert_select "h3", text: @recipe.title
    assert_select "h3", text: recipes(:bread).title, count: 0
  end

  test "should get new when logged in" do
    login(@user)

    get new_recipe_url

    assert_response :success
  end

  test "should redirect guest from new" do
    get new_recipe_url

    assert_redirected_to new_session_path
  end

  test "should create recipe as pending for non admin user" do
    login(@user)

    assert_difference("Recipe.count") do
      post recipes_url, params: {
        recipe: {
          slug: SecureRandom.uuid,
          tag_names: "Vegan, Dinner",
          title: "Weeknight Chili",
          blurb: "A fast pantry chili.",
          ingredient_list: "2 cans black beans\n1 tbsp chili powder\n1 onion, diced",
          instructions: Faker::Lorem.paragraph,
          category_id: categories(:one).id,
          image: fixture_file_upload("vaporwave.jpeg", "image/jpg")
        }
      }
    end

    recipe = Recipe.last
    assert_redirected_to recipe_url(recipe.slug)
    assert recipe.pending?
    assert_equal 3, recipe.recipe_ingredients.count
  end

  test "admin created recipes are auto approved" do
    login(@admin)

    assert_difference("Recipe.count") do
      post recipes_url, params: {
        recipe: {
          slug: SecureRandom.uuid,
          tag_names: @recipe.tag_names,
          title: "Admin Recipe",
          blurb: @recipe.blurb,
          ingredient_list: "2 cups flour\n1 tsp yeast",
          instructions: Faker::Lorem.paragraph,
          category_id: categories(:one).id,
          image: fixture_file_upload("vaporwave.jpeg", "image/jpg")
        }
      }
    end

    assert Recipe.last.approved?
  end

  test "should show approved recipe" do
    get recipe_url(@recipe)

    assert_response :success
  end

  test "should show cook mode and print view" do
    get cook_recipe_url(@recipe.slug, servings: 2)
    assert_response :success
    assert_select "h1", text: @recipe.title
    assert_select "p", text: /2 servings/

    get print_recipe_url(@recipe.slug, servings: 2)
    assert_response :success
    assert_match "Print / Save as PDF", response.body
  end

  test "show json includes servings and nutrition payload" do
    @recipe.update_columns(
      servings: 4,
      nutrition_calories: 320,
      nutrition_protein_grams: 12.5,
      nutrition_carbs_grams: 42.0,
      nutrition_fat_grams: 9.0,
      nutrition_match_count: 3,
      nutrition_missing_ingredients_count: 0,
      nutrition_computed_at: Time.current
    )

    get recipe_url(@recipe.slug, format: :json)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 4, json["servings"]
    assert_equal true, json.dig("nutrition", "available")
    assert_equal 320, json.dig("nutrition", "calories")
  end

  test "should hide pending recipe from guests" do
    get recipe_url(@pending_recipe.slug)

    assert_response :not_found
  end

  test "author can view pending recipe" do
    login(@user)

    get recipe_url(@pending_recipe.slug)

    assert_response :success
    assert_select "span", text: "Pending review"
  end

  test "show page includes related recipes" do
    get recipe_url(@recipe.slug)

    assert_response :success
    assert_select "h2", text: "Related recipes"
    assert_select "h3", text: recipes(:bread).title
  end

  test "should get edit for owner" do
    login(@user)

    get edit_recipe_url(@pending_recipe)

    assert_response :success
  end

  test "should update recipe and keep it pending for non admin" do
    login(@user)

    patch recipe_url(@pending_recipe), params: {
      recipe: {
        title: "Updated pending soup",
        instructions: Faker::Lorem.paragraph,
        image: fixture_file_upload("vaporwave.jpeg", "image/jpg")
      }
    }

    assert_redirected_to recipe_url(@pending_recipe.slug)
    @pending_recipe.reload
    assert_equal "Updated pending soup", @pending_recipe.title
    assert @pending_recipe.pending?
  end

  test "should destroy recipe" do
    login(@admin)

    assert_difference("Recipe.count", -1) do
      delete recipe_url(@recipe)
    end

    assert_redirected_to recipes_url
  end

  test "should get new with generation prefill" do
    login(@user)
    generation = recipe_generations(:one)

    get new_recipe_url(generation_id: generation.id)
    assert_response :success

    assert_select "input[value='#{generation.data['title']}']"
    assert_select "textarea", text: generation.data["blurb"]
    assert_select "textarea", text: /12 oz pasta/
    assert_select "input[name='recipe[generation_id]'][value='#{generation.id}']"
    assert_select "input[type='file'][name='recipe[image]']", count: 0
  end

  test "should create recipe from generation data" do
    login(@user)
    generation = recipe_generations(:one)

    assert_difference("Recipe.count") do
      post recipes_url, params: {
        recipe: {
          generation_id: generation.id,
          slug: SecureRandom.uuid,
          tag_names: generation.data["tags"].join(", "),
          title: generation.data["title"],
          blurb: generation.data["blurb"],
          ingredient_list: Recipe::IngredientParser.format(generation.data["ingredients"]),
          instructions: generation.data["instructions"],
          category_id: categories(:one).id,
          difficulty: generation.data["difficulty"],
          prep_time: generation.data["prep_time"],
          cost: generation.data["cost"],
          image: fixture_file_upload("vaporwave.jpeg", "image/jpg")
        }
      }
    end

    recipe = Recipe.last
    assert_redirected_to recipe_url(recipe.slug)
    assert_equal generation.data["title"], recipe.title
    assert recipe.pending?
    assert_equal generation.data["ingredients"].size, recipe.recipe_ingredients.count
  end
end
