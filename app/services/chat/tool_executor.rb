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
    when "get_seed_preview" then get_seed_preview(args)
    when "publish_seed_recipe" then publish_seed_recipe(args)
    when "list_seed_runs" then list_seed_runs
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

    generation = Recipe::SeedRunCreator.new(user: user).call(
      attributes: seed_attributes_from(args),
      auto_publish: ActiveModel::Type::Boolean.new.cast(args["publish_immediately"])
    )

    seed_preview_summary(generation).to_json
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

  def seed_run_status(generation)
    return "published" if generation.published_recipe.present?
    return "needs_attention" if generation.seed_publish_error.present?
    return "ready" if generation.complete?

    "generating"
  end

  def seed_image_urls(generation)
    urls = []
    urls << rails_blob_path(generation.image, only_path: true) if generation.image.attached?
    urls.concat(generation.images.map { |image| rails_blob_path(image, only_path: true) })
    urls
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
