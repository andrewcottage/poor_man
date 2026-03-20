class Chat::ToolExecutor
  include Rails.application.routes.url_helpers

  def initialize(user:)
    @user = user
  end

  def call(tool_name:, arguments:)
    args = arguments.is_a?(String) ? JSON.parse(arguments) : arguments

    case tool_name
    when "search_recipes" then search_recipes(args)
    when "get_recipe_details" then get_recipe_details(args)
    when "get_user_favorites" then get_user_favorites
    when "get_user_collections" then get_user_collections
    when "get_user_recipes" then get_user_recipes
    when "get_categories" then get_categories
    when "get_trending_recipes" then get_trending_recipes
    when "get_user_ratings" then get_user_ratings
    when "preview_seed_recipe" then preview_seed_recipe(args)
    when "queue_seed_recipe_batch" then queue_seed_recipe_batch(args)
    when "preview_seed_category" then preview_seed_category(args)
    when "get_seed_category_preview" then get_seed_category_preview(args)
    when "publish_seed_category" then publish_seed_category(args)
    when "list_seed_category_runs" then list_seed_category_runs
    when "get_seed_preview" then get_seed_preview(args)
    when "publish_seed_recipe" then publish_seed_recipe(args)
    when "list_seed_runs" then list_seed_runs
    when "list_seed_recipes_by_category" then list_seed_recipes_by_category(args)
    else
      { error: "Unknown tool: #{tool_name}" }.to_json
    end
  rescue StandardError => error
    { error: error.message }.to_json
  end

  private

  attr_reader :user

  def search_recipes(args)
    params = {}
    params[:q] = args["query"] if args["query"].present?
    params[:difficulty] = args["difficulty"] if args["difficulty"].present?
    params[:prep_time] = args["max_prep_time"] if args["max_prep_time"].present?
    params[:cost] = args["max_cost"] if args["max_cost"].present?
    params[:dietary_tags] = args["dietary_tags"] if args["dietary_tags"].present?
    params[:sort] = args["sort"] if args["sort"].present?

    recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: params).call.limit(10)
    recipes.map { |recipe| recipe_summary(recipe) }.to_json
  end

  def get_recipe_details(args)
    recipe = Recipe.approved.find_by(slug: args["slug"])
    return { error: "Recipe not found" }.to_json unless recipe

    {
      title: recipe.title,
      slug: recipe.slug,
      blurb: recipe.blurb,
      difficulty: recipe.difficulty,
      prep_time: recipe.prep_time,
      servings: recipe.servings,
      cost: recipe.cost_cents.to_f / 100,
      category: recipe.category&.title,
      tags: recipe.tags.pluck(:name),
      ingredients: recipe.recipe_ingredients.map { |ingredient| "#{ingredient.quantity} #{ingredient.unit} #{ingredient.name}".strip },
      instructions: recipe.instructions.to_s.gsub(/<[^>]+>/, " ").squish.truncate(500),
      average_rating: recipe.ratings.average(:value)&.round(1),
      rating_count: recipe.ratings.count,
      favorite_count: recipe.favorites.count,
      author: recipe.author&.username,
      url: recipe_path(recipe.slug)
    }.to_json
  end

  def get_user_favorites
    recipes = user.favorite_recipes.approved.limit(20)
    recipes.map { |recipe| recipe_summary(recipe) }.to_json
  end

  def get_user_collections
    collections = user.collections.includes(collection_recipes: :recipe).limit(10)
    collections.map do |collection|
      {
        name: collection.name,
        description: collection.description,
        recipes: collection.recipes.limit(10).map { |recipe| recipe_summary(recipe) }
      }
    end.to_json
  end

  def get_user_recipes
    recipes = user.recipes.limit(20)
    recipes.map { |recipe| recipe_summary(recipe) }.to_json
  end

  def get_categories
    Category.all.map { |category| { title: category.title, slug: category.slug, recipe_count: category.recipies_count } }.to_json
  end

  def get_trending_recipes
    recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { sort: "popularity" }).call.limit(10)
    recipes.map { |recipe| recipe_summary(recipe) }.to_json
  end

  def get_user_ratings
    ratings = user.ratings.includes(:recipe).order(created_at: :desc).limit(20)
    ratings.map do |rating|
      {
        recipe_title: rating.recipe.title,
        recipe_slug: rating.recipe.slug,
        rating: rating.value,
        comment: rating.comment,
        url: recipe_path(rating.recipe.slug)
      }
    end.to_json
  end

  def preview_seed_recipe(args)
    return admin_only_error.to_json unless user.admin?

    auto_publish = ActiveModel::Type::Boolean.new.cast(args["publish_immediately"]) || false
    generation = Recipe::SeedRunCreator.new(user: user).call(
      attributes: seed_attributes_from(args),
      auto_publish: auto_publish
    )

    seed_preview_summary(generation).to_json
  end

  def queue_seed_recipe_batch(args)
    return admin_only_error.to_json unless user.admin?

    auto_publish = ActiveModel::Type::Boolean.new.cast(args["publish_immediately"]) || false
    result = Recipe::SeedBatchCreator.new(user: user).call(
      category_names: args["category_names"],
      count_per_category: args["count_per_category"],
      dietary_preference: args["dietary_preference"],
      skill_level: args["skill_level"],
      avoid_ingredients: args["avoid_ingredients"],
      ingredient_swaps: args["ingredient_swaps"],
      customization_notes: args["customization_notes"],
      servings: args["servings"].presence || 4,
      target_difficulty: args["target_difficulty"],
      auto_publish: auto_publish
    )

    {
      status: "queued",
      message: "Queued #{result.total_count} recipe preview#{'s' if result.total_count != 1} across #{result.category_names.count} categor#{result.category_names.count == 1 ? 'y' : 'ies'}.",
      total_count: result.total_count,
      count_per_category: result.count_per_category,
      categories: result.category_names.map do |category_name|
        queued = result.generations.select { |generation| inferred_category_from_notes(generation) == category_name }

        {
          category: category_name,
          queued_count: queued.count,
          previews: queued.first(5).map { |generation| queued_seed_preview_summary(generation) }
        }
      end,
      admin_seed_studio_url: admin_seed_recipes_path
    }.to_json
  rescue ArgumentError => error
    { error: error.message }.to_json
  end

  def preview_seed_category(args)
    return admin_only_error.to_json unless user.admin?

    auto_publish = ActiveModel::Type::Boolean.new.cast(args["publish_immediately"]) || false
    category_seed_run = CategorySeedRunCreator.new(user: user).call(
      prompt: args["prompt"],
      auto_publish: auto_publish
    )

    category_seed_preview_summary(category_seed_run).to_json
  end

  def get_seed_category_preview(args)
    return admin_only_error.to_json unless user.admin?

    category_seed_run = user.category_seed_runs.find_by(id: args["category_seed_run_id"]) ||
      CategorySeedRun.find_by(id: args["category_seed_run_id"])
    return { error: "Category seed preview not found" }.to_json unless category_seed_run

    category_seed_preview_summary(category_seed_run).to_json
  end

  def publish_seed_category(args)
    return admin_only_error.to_json unless user.admin?

    category_seed_run = CategorySeedRun.find_by(id: args["category_seed_run_id"])
    return { error: "Category seed preview not found" }.to_json unless category_seed_run

    category = CategorySeedRunPublisher.new(category_seed_run).call

    category_seed_preview_summary(category_seed_run.reload).merge(
      published: true,
      category_record: {
        title: category.title,
        slug: category.slug,
        url: category_path(category.slug)
      }
    ).to_json
  rescue CategorySeedRunPublisher::PublishError => error
    { error: error.message }.to_json
  end

  def list_seed_category_runs
    return admin_only_error.to_json unless user.admin?

    CategorySeedRun.recent_first.limit(10).map do |category_seed_run|
      category_seed_preview_summary(category_seed_run)
    end.to_json
  end

  def get_seed_preview(args)
    return admin_only_error.to_json unless user.admin?

    generation = user.recipe_generations.seed_runs.find_by(id: args["generation_id"]) ||
      Recipe::Generation.seed_runs.find_by(id: args["generation_id"])
    return { error: "Seed preview not found" }.to_json unless generation

    seed_preview_summary(generation).to_json
  end

  def publish_seed_recipe(args)
    return admin_only_error.to_json unless user.admin?

    generation = Recipe::Generation.seed_runs.find_by(id: args["generation_id"])
    return { error: "Seed preview not found" }.to_json unless generation

    recipe = Recipe::GenerationPublisher.new(generation).call

    seed_preview_summary(generation.reload).merge(
      published: true,
      recipe: {
        title: recipe.title,
        slug: recipe.slug,
        url: recipe_path(recipe.slug)
      }
    ).to_json
  rescue Recipe::GenerationPublisher::PublishError => error
    { error: error.message }.to_json
  end

  def list_seed_runs
    return admin_only_error.to_json unless user.admin?

    Recipe::Generation.seed_runs.order(created_at: :desc).limit(10).map do |generation|
      seed_preview_summary(generation)
    end.to_json
  end

  def list_seed_recipes_by_category(args)
    return admin_only_error.to_json unless user.admin?

    category_names = Array(args["category_names"]).map(&:to_s).reject(&:blank?)
    generations = Recipe::Generation.seed_runs.order(created_at: :desc).limit(100)
    grouped = generations.group_by do |generation|
      generation.data["category"].presence || inferred_category_from_notes(generation) || "Uncategorized"
    end
    grouped.select! { |category, _| category.in?(category_names) } if category_names.any?

    grouped.map do |category_name, category_generations|
      {
        category: category_name,
        runs: category_generations.first(10).map { |generation| seed_preview_summary(generation) }
      }
    end.to_json
  end

  def seed_attributes_from(args)
    {
      prompt: args["prompt"],
      dietary_preference: args["dietary_preference"],
      skill_level: args["skill_level"],
      avoid_ingredients: args["avoid_ingredients"],
      ingredient_swaps: args["ingredient_swaps"],
      customization_notes: args["customization_notes"],
      servings: args["servings"].presence || 4,
      target_difficulty: args["target_difficulty"]
    }
  end

  def seed_preview_summary(generation)
    {
      generation_id: generation.id,
      prompt: generation.prompt,
      status: seed_run_status(generation),
      title: generation.data["title"],
      blurb: generation.data["blurb"],
      category: generation.data["category"],
      tags: Array(generation.data["tags"]),
      preview_url: admin_seed_recipe_path(generation),
      image_urls: seed_image_urls(generation),
      published: generation.published_recipe.present?,
      published_recipe_url: generation.published_recipe.present? ? recipe_path(generation.published_recipe.slug) : nil,
      seed_publish_error: generation.seed_publish_error
    }
  end

  def queued_seed_preview_summary(generation)
    {
      generation_id: generation.id,
      prompt: generation.prompt,
      status: seed_run_status(generation),
      preview_url: admin_seed_recipe_path(generation)
    }
  end

  def category_seed_preview_summary(category_seed_run)
    {
      category_seed_run_id: category_seed_run.id,
      prompt: category_seed_run.prompt,
      status: category_seed_run_status(category_seed_run),
      title: category_seed_run.data["title"],
      slug: category_seed_run.data["slug"],
      description: category_seed_run.data["description"],
      preview_url: admin_seed_category_path(category_seed_run),
      image_urls: category_seed_image_urls(category_seed_run),
      published: category_seed_run.published_category.present?,
      published_category_url: category_seed_run.published_category.present? ? category_path(category_seed_run.published_category.slug) : nil,
      seed_publish_error: category_seed_run.seed_publish_error
    }
  end

  def seed_run_status(generation)
    return "published" if generation.published_recipe.present?
    return "needs_attention" if generation.seed_publish_error.present?
    return "ready" if generation.complete?

    "generating"
  end

  def category_seed_run_status(category_seed_run)
    return "published" if category_seed_run.published_category.present?
    return "needs_attention" if category_seed_run.seed_publish_error.present?
    return "ready" if category_seed_run.complete?

    "generating"
  end

  def seed_image_urls(generation)
    urls = []
    urls << rails_blob_path(generation.image, only_path: true) if generation.image.attached?
    urls.concat(generation.images.map { |image| rails_blob_path(image, only_path: true) })
    urls
  end

  def category_seed_image_urls(category_seed_run)
    return [] unless category_seed_run.image.attached?

    [ rails_blob_path(category_seed_run.image, only_path: true) ]
  end

  def inferred_category_from_notes(generation)
    match = generation.customization_notes.to_s.match(/exact category title "([^"]+)"/i)
    match&.captures&.first
  end

  def recipe_summary(recipe)
    {
      title: recipe.title,
      slug: recipe.slug,
      blurb: recipe.blurb&.truncate(120),
      difficulty: recipe.difficulty,
      prep_time: recipe.prep_time,
      category: recipe.category&.title,
      url: recipe_path(recipe.slug)
    }
  end

  def admin_only_error
    { error: "This tool is only available to admins." }
  end
end
