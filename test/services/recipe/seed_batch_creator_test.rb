require "test_helper"

class Recipe::SeedBatchCreatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "queues recipe generations for each category" do
    result = nil

    assert_difference("Recipe::Generation.count", 4) do
      result = Recipe::SeedBatchCreator.new(user: @user).call(
        category_names: [ "Breakfast", "Dinner" ],
        count_per_category: 2,
        dietary_preference: "vegetarian",
        customization_notes: "Keep them broadly appealing."
      )
    end

    assert_equal 4, result.total_count
    assert_equal [ "Breakfast", "Dinner" ], result.category_names
    assert result.generations.all?(&:seed_tool?)
    assert result.generations.all? { |generation| generation.customization_notes.include?("Use the exact category title") }
  end

  test "raises when batch size is too large" do
    error = assert_raises(ArgumentError) do
      Recipe::SeedBatchCreator.new(user: @user).call(
        category_names: Array.new(10) { |index| "Category #{index}" },
        count_per_category: 7
      )
    end

    assert_match(/limited/, error.message)
  end
end
