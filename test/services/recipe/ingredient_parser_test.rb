require "test_helper"

class Recipe::IngredientParserTest < ActiveSupport::TestCase
  test "parses one ingredient per line into structured attributes" do
    parsed = Recipe::IngredientParser.parse(<<~TEXT)
      2 cups flour
      1 tsp kosher salt
      3 tbsp olive oil, plus more for the pan
    TEXT

    assert_equal 3, parsed.size
    assert_equal "2", parsed.first[:quantity]
    assert_equal "cups", parsed.first[:unit]
    assert_equal "flour", parsed.first[:name]
    assert_equal "plus more for the pan", parsed.third[:notes]
  end

  test "parses structured ingredient payloads from AI" do
    parsed = Recipe::IngredientParser.parse_structured(
      [
        { quantity: "1", unit: "cup", name: "lentils", notes: "red" },
        { quantity: "2", unit: "tbsp", name: "curry paste" }
      ]
    )

    assert_equal 2, parsed.size
    assert_equal "1 cup lentils, red", parsed.first[:raw]
    assert_equal "curry paste", parsed.second[:name]
  end

  test "formats parsed ingredients back into textarea-friendly text" do
    formatted = Recipe::IngredientParser.format(
      [
        { quantity: "2", unit: "cups", name: "flour" },
        { quantity: "1", unit: "tsp", name: "salt", notes: "kosher" }
      ]
    )

    assert_equal "2 cups flour\n1 tsp salt, kosher", formatted
  end
end
