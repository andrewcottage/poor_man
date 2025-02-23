json.extract! @recipe, :id, :title, :slug, :tags, :blurb, :created_at, :updated_at

json.image do
  json.url url_for(@recipe.image) if @recipe.image.attached?
end

json.images @recipe.images do |image|
  json.url url_for(image)
end

json.author do
  json.extract! @recipe.author, :username
end

json.category do
  json.extract! @recipe.category, :id, :title, :slug, :description
end

json.instructions @recipe.instructions.body.to_plain_text

