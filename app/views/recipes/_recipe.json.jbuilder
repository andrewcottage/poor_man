json.extract! recipe, :id, :title, :image, :slug, :content, :tags, :created_at, :updated_at
json.url recipe_url(recipe, format: :json)
json.image url_for(recipe.image)
json.content recipe.content.to_s
