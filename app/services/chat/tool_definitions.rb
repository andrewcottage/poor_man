class Chat::ToolDefinitions
  def initialize(user:)
    @user = user
  end

  def all
    base_tools + admin_seed_tools
  end

  private

  attr_reader :user

  def base_tools
    [
      {
        type: "function",
        function: {
          name: "search_recipes",
          description: "Search for recipes on the site. Use this to find recipes by keyword, filter by difficulty, prep time, cost, or dietary tags.",
          parameters: {
            type: "object",
            properties: {
              query: { type: "string", description: "Search term for recipe title, description, or tags" },
              difficulty: { type: "integer", description: "Exact difficulty level 1-5 (1=very easy, 5=very hard)" },
              max_prep_time: { type: "integer", description: "Maximum prep time in minutes" },
              max_cost: { type: "number", description: "Maximum ingredient cost in USD" },
              dietary_tags: { type: "array", items: { type: "string" }, description: "Dietary tags to filter by (e.g. 'vegetarian', 'gluten-free')" },
              sort: { type: "string", enum: %w[newest rating popularity], description: "Sort order" }
            }
          }
        }
      },
      {
        type: "function",
        function: {
          name: "get_recipe_details",
          description: "Get full details for a specific recipe including ingredients, instructions, nutrition, and ratings.",
          parameters: {
            type: "object",
            properties: {
              slug: { type: "string", description: "The recipe's URL slug" }
            },
            required: [ "slug" ]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "get_user_favorites",
          description: "Get the current user's favorite/liked recipes.",
          parameters: { type: "object", properties: {} }
        }
      },
      {
        type: "function",
        function: {
          name: "get_user_collections",
          description: "Get the current user's recipe collections.",
          parameters: { type: "object", properties: {} }
        }
      },
      {
        type: "function",
        function: {
          name: "get_user_recipes",
          description: "Get recipes authored/submitted by the current user.",
          parameters: { type: "object", properties: {} }
        }
      },
      {
        type: "function",
        function: {
          name: "get_categories",
          description: "Get all recipe categories available on the site.",
          parameters: { type: "object", properties: {} }
        }
      },
      {
        type: "function",
        function: {
          name: "get_trending_recipes",
          description: "Get the most popular and highly-rated recipes on the site right now.",
          parameters: { type: "object", properties: {} }
        }
      },
      {
        type: "function",
        function: {
          name: "get_user_ratings",
          description: "Get recipes the current user has rated, with their scores. Useful for understanding preferences.",
          parameters: { type: "object", properties: {} }
        }
      }
    ]
  end

  def admin_seed_tools
    return [] unless user.admin?

    [
      {
        type: "function",
        function: {
          name: "preview_seed_recipe",
          description: "Generate a photorealistic admin-only recipe preview with hero and gallery images. Use this before publishing unless the admin explicitly asks to publish immediately.",
          parameters: {
            type: "object",
            properties: {
              prompt: { type: "string", description: "What recipe to create" },
              dietary_preference: { type: "string", description: "Optional dietary preference like vegan or gluten-free" },
              skill_level: { type: "string", description: "Optional skill level like beginner or advanced" },
              avoid_ingredients: { type: "string", description: "Comma-separated ingredients to avoid" },
              ingredient_swaps: { type: "string", description: "Optional requested swaps" },
              customization_notes: { type: "string", description: "Extra editorial notes for the model" },
              servings: { type: "integer", description: "Desired servings" },
              target_difficulty: { type: "integer", description: "Target difficulty 1-5" },
              publish_immediately: { type: "boolean", description: "Set true only when the admin clearly wants the content published right away" }
            },
            required: [ "prompt" ]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "get_seed_preview",
          description: "Retrieve an existing admin seed preview or published run by generation id.",
          parameters: {
            type: "object",
            properties: {
              generation_id: { type: "integer", description: "Recipe generation id for the seed run" }
            },
            required: [ "generation_id" ]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "publish_seed_recipe",
          description: "Publish an existing admin seed preview into a live recipe. This will create the category if needed.",
          parameters: {
            type: "object",
            properties: {
              generation_id: { type: "integer", description: "Recipe generation id for the seed run" }
            },
            required: [ "generation_id" ]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "list_seed_runs",
          description: "List recent admin seed runs with their publish state and preview links.",
          parameters: { type: "object", properties: {} }
        }
      }
    ]
  end
end
