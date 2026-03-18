# == Schema Information
#
# Table name: recipes
#
#  id                                  :integer          not null, primary key
#  blurb                               :text
#  cost_cents                          :integer          default(0), not null
#  cost_currency                       :string           default("USD"), not null
#  difficulty                          :integer          default(0)
#  moderation_status                   :integer          default("pending"), not null
#  nutrition_calories                  :integer
#  nutrition_carbs_grams               :decimal(8, 2)
#  nutrition_computed_at               :datetime
#  nutrition_fat_grams                 :decimal(8, 2)
#  nutrition_match_count               :integer          default(0), not null
#  nutrition_missing_ingredients_count :integer          default(0), not null
#  nutrition_protein_grams             :decimal(8, 2)
#  prep_time                           :integer          default(0)
#  rejection_reason                    :text
#  reviewed_at                         :datetime
#  servings                            :integer          default(4), not null
#  slug                                :string
#  tag_names                           :string
#  title                               :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  author_id                           :integer
#  category_id                         :integer          not null
#  reviewed_by_id                      :integer
#
# Indexes
#
#  index_recipes_on_author_id          (author_id)
#  index_recipes_on_category_id        (category_id)
#  index_recipes_on_moderation_status  (moderation_status)
#  index_recipes_on_reviewed_by_id     (reviewed_by_id)
#  index_recipes_on_slug               (slug) UNIQUE
#
# Foreign Keys
#
#  author_id       (author_id => users.id)
#  category_id     (category_id => categories.id)
#  reviewed_by_id  (reviewed_by_id => users.id)
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

  test "slug should auto-generate from title when blank" do
    @recipe.slug = nil

    assert @recipe.valid?
    assert_equal "pizza", @recipe.slug
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

  test "non admin recipes are visible only to author and admins until approved" do
    recipe = recipes(:pending_recipe)

    assert_not recipe.visible_to?(nil)
    assert recipe.visible_to?(users(:user))
    assert recipe.visible_to?(users(:admin))
  end

  test "admin authored recipe is auto approved on create" do
    recipe = users(:admin).recipes.new(
      title: "Approved by default",
      slug: "approved-by-default",
      blurb: "Auto-approved admin recipe",
      instructions: "Cook it",
      category: categories(:one)
    )
    recipe.image.attach(io: file_fixture("vaporwave.jpeg").open, filename: "vaporwave.jpeg", content_type: "image/jpeg")

    assert recipe.valid?
    assert recipe.approved?
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
    assert_match "12 oz pasta", recipe.ingredient_list
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

  test "sync_recipe_ingredients parses textarea ingredient list" do
    @recipe.sync_recipe_ingredients!(ingredient_list: "2 cups flour\n1 tsp salt")

    assert_equal 2, @recipe.recipe_ingredients.count
    assert_equal "flour", @recipe.recipe_ingredients.ordered.first.name
  end

  test "sync_recipe_ingredients stores structured ingredient payload" do
    @recipe.sync_recipe_ingredients!(
      structured_ingredients: [
        { quantity: "1", unit: "cup", name: "lentils" },
        { quantity: "2", unit: "tbsp", name: "olive oil", notes: "extra virgin" }
      ]
    )

    assert_equal 2, @recipe.recipe_ingredients.count
    assert_equal "extra virgin", @recipe.recipe_ingredients.ordered.last.notes
  end

  test "scaled ingredients adjust quantities for target servings" do
    scaled = @recipe.scaled_ingredients(2)

    assert_equal "1 cup flour", scaled.first.display_text
    assert_equal 3, scaled.size
  end

  test "recalculate_nutrition stores per-serving estimate" do
    @recipe.sync_recipe_ingredients!(ingredient_list: "2 cups flour\n1 tsp yeast\n1 tsp salt")
    @recipe.reload

    assert @recipe.nutrition_available?
    assert_operator @recipe.nutrition_calories, :>, 0
    assert_equal 3, @recipe.nutrition_match_count
  end

  test "instruction steps parses action text into ordered steps" do
    @recipe.instructions = <<~TEXT
      1. Mix flour
      2. Add water
      3. Bake
    TEXT

    @recipe.save!

    assert_equal 3, @recipe.instruction_steps.size
    assert_match "Mix flour", @recipe.instruction_steps.first
  end

  test "related_recipes returns approved recipes in the same category" do
    assert_includes @recipe.related_recipes, recipes(:bread)
    assert_not_includes @recipe.related_recipes, recipes(:pending_recipe)
  end
end
