class Chat::ToolDefinitions
  def self.all
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
end
