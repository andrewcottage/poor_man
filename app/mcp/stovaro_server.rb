class StovaroServer
  INSTRUCTIONS = <<~INSTRUCTIONS
    You are a recipe assistant for Stovaro, a recipe discovery and meal planning platform.

    You can search recipes, view details, check user favorites/collections/ratings, and browse categories.

    Admin users also have seed tools for generating and publishing new recipes and categories.
    Always preview before publishing unless explicitly asked to publish immediately.
    Check existing categories with get_categories before creating new ones.
  INSTRUCTIONS

  def self.build(user:)
    MCP::Server.new(
      name: "stovaro",
      version: "1.0.0",
      instructions: INSTRUCTIONS,
      tools: tools_for(user: user),
      server_context: { user: user }
    )
  end

  def self.tools_for(user:)
    tools = base_tools
    tools += admin_tools if user.admin?
    tools
  end

  def self.find_tool(name:, user:)
    tools_for(user: user).find { |t| t.tool_name == name }
  end

  def self.base_tools
    [
      Tools::SearchRecipes,
      Tools::GetRecipeDetails,
      Tools::GetUserFavorites,
      Tools::GetUserCollections,
      Tools::GetUserRecipes,
      Tools::GetCategories,
      Tools::GetTrendingRecipes,
      Tools::GetUserRatings
    ]
  end

  def self.admin_tools
    [
      Tools::PreviewSeedRecipe,
      Tools::QueueSeedRecipeBatch,
      Tools::PreviewSeedCategory,
      Tools::GetSeedCategoryPreview,
      Tools::PublishSeedCategory,
      Tools::ListSeedCategoryRuns,
      Tools::GetSeedPreview,
      Tools::PublishSeedRecipe,
      Tools::ListSeedRuns,
      Tools::ListSeedRecipesByCategory
    ]
  end
end
