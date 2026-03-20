require "test_helper"
require Rails.root.join("db/seeds/catalog").to_s

class SeedCatalogLoaderTest < ActiveSupport::TestCase
  test "loads curated categories and recipes idempotently" do
    assert_difference("Category.count", 8) do
      assert_difference("Recipe.count", 10) do
        assert_difference("User.where(email: 'admin@stovaro.com').count", 1) do
          SeedCatalog::Loader.run
        end
      end
    end

    assert_no_difference("Category.count") do
      assert_no_difference("Recipe.count") do
        SeedCatalog::Loader.run
      end
    end

    breakfast = Category.find_by!(slug: "breakfast")
    pancakes = Recipe.find_by!(slug: "blueberry-buttermilk-pancakes")
    spaghetti = Recipe.find_by!(slug: "one-pot-tomato-basil-spaghetti")

    assert breakfast.image.attached?
    assert_equal breakfast, pancakes.category
    assert pancakes.image.attached?
    assert_equal "pasta", spaghetti.category.slug
    assert spaghetti.image.attached?
    assert spaghetti.approved?
    assert_equal 10, spaghetti.recipe_ingredients.count

    dietary_filter_results = RecipesHelper::DISCOVERY_DIETARY_TAGS.to_h do |tag|
      recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { dietary_tags: [ tag ] }).call
      [ tag, recipes.pluck(:slug) ]
    end

    assert_equal [ "oven-garlic-fries" ], dietary_filter_results.fetch("vegan")
    assert_includes dietary_filter_results.fetch("vegetarian"), "blueberry-buttermilk-pancakes"
    assert_includes dietary_filter_results.fetch("gluten-free"), "watermelon-feta-salad"
    assert_includes dietary_filter_results.fetch("dairy-free"), "slow-simmered-beef-stew"
    assert_includes dietary_filter_results.fetch("high-protein"), "caramelized-onion-burger-bowls"
  end
end
