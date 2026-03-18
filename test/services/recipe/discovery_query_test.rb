require "test_helper"

class Recipe::DiscoveryQueryTest < ActiveSupport::TestCase
  setup do
    @pizza = recipes(:pizza)
    @bread = recipes(:bread)

    @pizza.update_columns(difficulty: 1, prep_time: 20, cost_cents: 1200)
    @bread.update_columns(difficulty: 4, prep_time: 75, cost_cents: 2800)

    Tagging.create!(taggable: @pizza, tag: Tag.find_or_create_by!(name: "vegan"))
    Favorite.find_or_create_by!(user: users(:user), recipe: @pizza)
    Rating.find_or_create_by!(user: users(:pro_user), recipe: @pizza) do |rating|
      rating.value = 5
      rating.title = "Top tier"
      rating.comment = "Best one here"
    end
  end

  test "filters by difficulty, prep time, cost, and dietary tags" do
    results = Recipe::DiscoveryQuery.new(
      scope: Recipe.approved,
      params: { difficulty: "1", prep_time: "30", cost: "15", dietary_tags: [ "vegan" ] }
    ).call

    assert_equal [ @pizza ], results.to_a
  end

  test "sorts by popularity" do
    results = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { sort: "popularity" }).call

    assert_equal @pizza, results.first
  end
end
