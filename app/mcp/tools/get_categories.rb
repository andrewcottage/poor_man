class Tools::GetCategories < Tools::BaseTool
  tool_name "get_categories"
  description "Get all recipe categories available on the site."

  def self.call(server_context:)
    success_response(Category.all.map { |c| { title: c.title, slug: c.slug, recipe_count: c.recipies_count } })
  end
end
