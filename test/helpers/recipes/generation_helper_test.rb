require "test_helper"

class Recipes::GenerationHelperTest < ActionView::TestCase
  setup do
    @complete_generation = recipe_generations(:one)
    @processing_generation = recipe_generations(:processing)
  end

  test "generation_status_badge returns correct badge for generation with data" do
    badge = generation_status_badge(@complete_generation)
    assert_includes badge, "Recipe Generated"
    assert_includes badge, "bg-yellow-100"
    assert_includes badge, "text-yellow-800"
  end

  test "generation_status_badge returns correct badge for processing generation" do
    badge = generation_status_badge(@processing_generation)
    assert_includes badge, "Processing"
    assert_includes badge, "bg-blue-100"
    assert_includes badge, "text-blue-800"
  end

  test "generation_progress_bar returns correct progress for data only generation" do
    progress_bar = generation_progress_bar(@complete_generation)
    assert_includes progress_bar, "width: 33%"
  end

  test "generation_progress_bar returns correct progress for processing generation" do
    progress_bar = generation_progress_bar(@processing_generation)
    assert_includes progress_bar, "width: 0%"
  end

  test "formatted_generation_data returns proper formatted data" do
    formatted = formatted_generation_data(@complete_generation)
    assert_includes formatted, "Pasta with Tomatoes and Basil"
    assert_includes formatted, "A simple and delicious pasta dish"
    assert_includes formatted, "pasta"
    assert_includes formatted, "Category: Dinner"
  end

  test "formatted_generation_data returns message for no data" do
    formatted = formatted_generation_data(@processing_generation)
    assert_equal "No data generated yet", formatted
  end
end 