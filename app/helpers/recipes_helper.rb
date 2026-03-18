module RecipesHelper
  DISCOVERY_DIETARY_TAGS = %w[vegan vegetarian gluten-free dairy-free high-protein].freeze

  def recipe_moderation_badge(recipe)
    case recipe.moderation_status
    when "approved"
      content_tag(:span, "Approved", class: "inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-800")
    when "rejected"
      content_tag(:span, "Needs changes", class: "inline-flex items-center rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800")
    else
      content_tag(:span, "Pending review", class: "inline-flex items-center rounded-full bg-yellow-100 px-2 py-1 text-xs font-medium text-yellow-800")
    end
  end

  def recipe_sort_options
    [
      [ "Newest", "newest" ],
      [ "Top rated", "rating" ],
      [ "Most popular", "popularity" ]
    ]
  end

  def recipe_difficulty_options
    (1..5).map { |difficulty| [ "Difficulty #{difficulty}", difficulty ] }
  end

  def recipe_prep_time_options
    [
      [ "15 minutes", 15 ],
      [ "30 minutes", 30 ],
      [ "45 minutes", 45 ],
      [ "60 minutes", 60 ]
    ]
  end

  def recipe_cost_options
    [
      [ "$10 or less", 10 ],
      [ "$20 or less", 20 ],
      [ "$30 or less", 30 ],
      [ "$40 or less", 40 ]
    ]
  end
end
