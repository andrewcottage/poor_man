# == Schema Information
#
# Table name: recipe_generations
#
#  id                  :integer          not null, primary key
#  avoid_ingredients   :text
#  customization_notes :text
#  data                :text
#  dietary_preference  :string
#  ingredient_swaps    :text
#  prompt              :text
#  servings            :integer          default(4), not null
#  skill_level         :string
#  target_difficulty   :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :integer          not null
#
# Indexes
#
#  index_recipe_generations_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "test_helper"

class Recipe::GenerationTest < ActiveSupport::TestCase
  setup do
    @user = users(:andrew)
    @generation = Recipe::Generation.new(
      user: @user,
      prompt: "A delicious test recipe"
    )
  end

  test "should be valid with valid attributes" do
    assert @generation.valid?
  end

  test "should require prompt" do
    @generation.prompt = nil
    assert_not @generation.valid?
    assert_includes @generation.errors[:prompt], "can't be blank"
  end

  test "should require user" do
    @generation.user = nil
    assert_not @generation.valid?
    assert_includes @generation.errors[:user], "must exist"
  end

  test "should serialize data as JSON" do
    test_data = { "title" => "Test Recipe", "ingredients" => ["flour", "sugar"] }
    @generation.data = test_data
    @generation.save!
    
    @generation.reload
    assert_equal test_data, @generation.data
  end

  test "complete? should return false when no data or images" do
    assert_not @generation.complete?
  end

  test "complete? should return false when only data present" do
    @generation.data = { "title" => "Test Recipe" }
    assert_not @generation.complete?
  end

  test "should belong to user" do
    assert_equal @user, @generation.user
  end

  test "should validate servings and target difficulty bounds" do
    @generation.servings = 0
    @generation.target_difficulty = 6

    assert_not @generation.valid?
    assert_includes @generation.errors[:servings], "must be greater than 0"
    assert_includes @generation.errors[:target_difficulty], "must be less than or equal to 5"
  end
end
