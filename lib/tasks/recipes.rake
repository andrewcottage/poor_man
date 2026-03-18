namespace :recipes do
  recipe_scope = lambda do
    scope = Recipe.includes(:recipe_ingredients)
    scope = scope.where(id: ENV["RECIPE_ID"]) if ENV["RECIPE_ID"].present?
    scope
  end

  only_missing = lambda do
    ActiveModel::Type::Boolean.new.cast(ENV["ONLY_MISSING"])
  end

  batch_size = lambda do
    value = ENV.fetch("BATCH_SIZE", "100").to_i
    value.positive? ? value : 100
  end

  process_recipes = lambda do |scope, &block|
    scope.find_each(batch_size: batch_size.call) do |recipe|
      block.call(recipe)
    rescue StandardError => e
      warn "Failed #{recipe.id}: #{recipe.title} (#{e.class}: #{e.message})"
    end
  end

  desc "Parse and backfill structured ingredients for recipes"
  task parse_ingredients: :environment do
    scope = recipe_scope.call
    scope = scope.left_outer_joins(:recipe_ingredients).where(recipe_ingredients: { id: nil }).distinct if only_missing.call

    process_recipes.call(scope) do |recipe|
      recipe.sync_recipe_ingredients!
      puts "Parsed ingredients for #{recipe.id}: #{recipe.title}"
    end
  end

  desc "Backfill nutrition estimates for recipes that already have structured ingredients"
  task backfill_nutrition: :environment do
    scope = recipe_scope.call
    scope = scope.where(nutrition_computed_at: nil) if only_missing.call

    process_recipes.call(scope) do |recipe|
      unless recipe.recipe_ingredients.exists?
        warn "Skipped #{recipe.id}: #{recipe.title} (no structured ingredients)"
        next
      end

      recipe.recalculate_nutrition!
      puts "Recalculated nutrition for #{recipe.id}: #{recipe.title}"
    end
  end

  desc "Backfill structured ingredients and nutrition metadata for recipes"
  task backfill_metadata: :environment do
    scope = recipe_scope.call

    if only_missing.call
      scope = scope.left_outer_joins(:recipe_ingredients)
                   .where("recipe_ingredients.id IS NULL OR recipes.nutrition_computed_at IS NULL")
                   .distinct
    end

    process_recipes.call(scope) do |recipe|
      if recipe.recipe_ingredients.exists? && recipe.nutrition_computed_at.blank?
        recipe.recalculate_nutrition!
        puts "Recalculated nutrition for #{recipe.id}: #{recipe.title}"
      else
        recipe.sync_recipe_ingredients!
        puts "Parsed ingredients and recalculated nutrition for #{recipe.id}: #{recipe.title}"
      end
    end
  end
end
