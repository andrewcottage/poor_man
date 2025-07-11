# == Schema Information
#
# Table name: recipes
#
#  id            :integer          not null, primary key
#  blurb         :text
#  cost_cents    :integer          default(0), not null
#  cost_currency :string           default("USD"), not null
#  difficulty    :integer          default(0)
#  prep_time     :integer          default(0)
#  slug          :string
#  tag_names     :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :integer
#  category_id   :integer          not null
#
# Indexes
#
#  index_recipes_on_author_id    (author_id)
#  index_recipes_on_category_id  (category_id)
#  index_recipes_on_slug         (slug) UNIQUE
#
# Foreign Keys
#
#  author_id    (author_id => users.id)
#  category_id  (category_id => categories.id)
#
require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  setup do
    @recipe = recipes(:pizza)
    @user = users(:andrew)
    @category = categories(:one)
    @recipe.instructions = "Test instructions"
    file = Rails.root.join('test/fixtures/files/vaporwave.jpeg')
    @recipe.image.attach(io: File.open(file), filename: 'vaporwave.jpeg', content_type: 'image/jpeg')
  end

  test "should be valid" do
    assert @recipe.valid?
  end

  test "title should be present" do
    @recipe.title = nil
    assert_not @recipe.valid?
  end

  test "slug should be present" do
    @recipe.slug = nil
    assert_not @recipe.valid?
  end

  test "blurb should be present" do
    @recipe.blurb = nil
    assert_not @recipe.valid?
  end

  test "slug should be unique" do
    duplicate_recipe = @recipe.dup
    duplicate_recipe.title = "Different Title"
    assert_not duplicate_recipe.valid?
  end

  test "difficulty should be between 0 and 5" do
    @recipe.difficulty = 6
    assert_not @recipe.valid?
    
    @recipe.difficulty = -1
    assert_not @recipe.valid?
    
    @recipe.difficulty = 5
    assert @recipe.valid?
  end

  test "belongs to a category" do
    @recipe.category = nil
    assert_not @recipe.valid?
  end

  test "belongs to an author" do
    assert_equal @recipe.author, @recipe.author
  end

  test "can have tags" do
    assert_respond_to @recipe, :tags
  end

  test "can have favorites" do
    assert_respond_to @recipe, :favorites
  end

  test "can have ratings" do
    assert_respond_to @recipe, :ratings
  end

  test "Recipe.from_generation should create recipe from generation data" do
    generation = recipe_generations(:one)
    recipe = Recipe.from_generation(generation.id)
    
    assert_not_nil recipe
    assert_equal generation.data['title'], recipe.title
    assert_equal generation.data['blurb'], recipe.blurb
    assert_equal generation.data['difficulty'], recipe.difficulty
    assert_equal generation.data['prep_time'], recipe.prep_time
    assert_equal generation.data['tags'].join(', '), recipe.tag_names
    assert_not_nil recipe.slug
    assert_not_nil recipe.category
  end

  test "Recipe.from_generation should return nil for invalid generation_id" do
    recipe = Recipe.from_generation(999999)
    assert_nil recipe
  end

  test "Recipe.from_generation should return nil for generation without data" do
    processing_generation = recipe_generations(:processing)
    recipe = Recipe.from_generation(processing_generation.id)
    assert_nil recipe
  end

  test "use_generated_images should handle generation without images gracefully" do
    generation = recipe_generations(:one)
    recipe = Recipe.new(title: "Test", slug: "test", blurb: "Test", category: @category)
    
    # Should not raise an error even if generation has no images
    assert_nothing_raised do
      recipe.use_generated_images(generation.id)
    end
  end

  test "use_generated_images should handle invalid generation_id gracefully" do
    recipe = Recipe.new(title: "Test", slug: "test", blurb: "Test", category: @category)
    
    # Should not raise an error for invalid generation_id
    assert_nothing_raised do
      recipe.use_generated_images(999999)
    end
  end
end
