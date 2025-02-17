json.array! @recipes do |recipe|
  json.url recipe_url(recipe.slug)
  json.id recipe.id
  json.name recipe.name
  json.description recipe.description
  json.created_at recipe.created_at
  json.updated_at recipe.updated_at
end