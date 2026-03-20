require "test_helper"

class OpenAI::StructuredOutputTest < ActiveSupport::TestCase
  test "parses plain json object" do
    parsed = OpenAI::StructuredOutput.parse_json_object!({ "text" => '{"title":"Soup"}' })

    assert_equal "Soup", parsed["title"]
  end

  test "parses fenced json object" do
    parsed = OpenAI::StructuredOutput.parse_json_object!(<<~CONTENT)
      ```json
      {"title":"Soup","category":"Dinner"}
      ```
    CONTENT

    assert_equal "Soup", parsed["title"]
    assert_equal "Dinner", parsed["category"]
  end

  test "extracts first object from surrounding prose" do
    parsed = OpenAI::StructuredOutput.parse_json_object!("Here you go:\n{\"title\":\"Soup\"}\nEnjoy!")

    assert_equal "Soup", parsed["title"]
  end
end
