class Chat::ToolExecutor
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
    else
      { error: "Unknown tool: #{tool_name}" }.to_json
    end
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
    recipes.map { |r| recipe_summary(r) }.to_json
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
      ingredients: recipe.recipe_ingredients.map { |i| "#{i.quantity} #{i.unit} #{i.name}".strip },
      instructions: recipe.instructions.to_s.gsub(/<[^>]+>/, " ").squish.truncate(500),
      average_rating: recipe.ratings.average(:value)&.round(1),
      rating_count: recipe.ratings.count,
      favorite_count: recipe.favorites.count,
      author: recipe.author&.username,
      url: "/recipes/#{recipe.slug}"
    }.to_json
  end

  def get_user_favorites
    recipes = user.favorite_recipes.approved.limit(20)
    recipes.map { |r| recipe_summary(r) }.to_json
  end

  def get_user_collections
    collections = user.collections.includes(collection_recipes: :recipe).limit(10)
    collections.map do |c|
      {
        name: c.name,
        description: c.description,
        recipes: c.recipes.limit(10).map { |r| recipe_summary(r) }
      }
    end.to_json
  end

  def get_user_recipes
    recipes = user.recipes.limit(20)
    recipes.map { |r| recipe_summary(r) }.to_json
  end

  def get_categories
    Category.all.map { |c| { title: c.title, slug: c.slug, recipe_count: c.recipies_count } }.to_json
  end

  def get_trending_recipes
    recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: { sort: "popularity" }).call.limit(10)
    recipes.map { |r| recipe_summary(r) }.to_json
  end

  def get_user_ratings
    ratings = user.ratings.includes(:recipe).order(created_at: :desc).limit(20)
    ratings.map do |r|
      {
        recipe_title: r.recipe.title,
        recipe_slug: r.recipe.slug,
        rating: r.value,
        comment: r.comment,
        url: "/recipes/#{r.recipe.slug}"
      }
    end.to_json
  end

  def recipe_summary(recipe)
    {
      title: recipe.title,
      slug: recipe.slug,
      blurb: recipe.blurb&.truncate(120),
      difficulty: recipe.difficulty,
      prep_time: recipe.prep_time,
      category: recipe.category&.title,
      url: "/recipes/#{recipe.slug}"
    }
  end
end
