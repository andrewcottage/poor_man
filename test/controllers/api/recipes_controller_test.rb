require "test_helper"

class Api::RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @category = categories(:one)
    @owned_recipe = Recipe.new(
      author: @user,
      category: @category,
      title: "Owned Recipe",
      slug: "owned-recipe",
      tag_names: "Vegan, Dinner",
      blurb: "A recipe owned by the non-admin user.",
      instructions: "<p>Cook it well.</p>",
      difficulty: 2,
      prep_time: 20,
      cost: 9.50
    )
    @owned_recipe.image.attach(
      io: file_fixture("vaporwave.jpeg").open,
      filename: "owned-recipe.jpg",
      content_type: "image/jpeg"
    )
    @owned_recipe.save!
  end

  test "should create recipe with bearer auth and category slug" do
    assert_difference("Recipe.count", 1) do
      post api_recipes_url, params: {
        recipe: {
          title: "Vegan Chili",
          blurb: "A smoky weeknight chili.",
          instructions: "<p>Simmer everything until thick.</p>",
          tag_names: "Vegan, Chili, Dinner",
          difficulty: 2,
          prep_time: 35,
          cost: 12.25,
          category_slug: @category.slug,
          image: fixture_file_upload("vaporwave.jpeg", "image/jpeg"),
          images: [
            fixture_file_upload("vaporwave.jpeg", "image/jpeg"),
            fixture_file_upload("vaporwave.jpeg", "image/jpeg")
          ]
        }
      }, headers: bearer_headers(@user)
    end

    recipe = Recipe.order(:id).last

    assert_response :created
    assert_equal @user, recipe.author
    assert_equal @category, recipe.category
    assert_equal "vegan-chili", recipe.slug
    assert_equal 2, recipe.images.count

    json = JSON.parse(response.body)
    assert_equal recipe.slug, json["slug"]
    assert_equal @user.email, json.dig("author", "email")
  end

  test "should update own recipe with x api key auth" do
    patch api_recipe_url(@owned_recipe.slug), params: {
      recipe: {
        title: "Updated Owned Recipe",
        blurb: "An updated blurb.",
        instructions: "<p>Updated instructions.</p>",
        tag_names: "Vegan, Updated",
        difficulty: 3,
        prep_time: 25,
        cost: 10.75
      }
    }, headers: api_key_headers(@user)

    assert_response :ok

    @owned_recipe.reload
    assert_equal "Updated Owned Recipe", @owned_recipe.title
    assert_equal "owned-recipe", @owned_recipe.slug
  end

  test "should reject create without api auth" do
    assert_no_difference("Recipe.count") do
      post api_recipes_url, params: {
        recipe: {
          title: "Unauthorized Recipe",
          blurb: "Should not be created.",
          instructions: "<p>No auth.</p>",
          category_slug: @category.slug
        }
      }
    end

    assert_response :unauthorized
  end

  test "should reject create with invalid category slug" do
    assert_no_difference("Recipe.count") do
      post api_recipes_url, params: {
        recipe: {
          title: "Invalid Category Recipe",
          blurb: "Should not be created.",
          instructions: "<p>Bad category.</p>",
          category_slug: "missing-category",
          image: fixture_file_upload("vaporwave.jpeg", "image/jpeg")
        }
      }, headers: bearer_headers(@user)
    end

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_includes json["errors"], "Category must exist"
  end

  test "should reject updating another users recipe" do
    patch api_recipe_url(recipes(:pizza).slug), params: {
      recipe: {
        title: "Nope"
      }
    }, headers: api_key_headers(@user)

    assert_response :forbidden
  end

  private

  def bearer_headers(user)
    { "Authorization" => "Bearer #{user.api_key}" }
  end

  def api_key_headers(user)
    { "X-Api-Key" => user.api_key }
  end
end
