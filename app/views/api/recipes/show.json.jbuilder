json.extract! @recipe, :id, :title, :slug, :blurb, :difficulty, :prep_time, :created_at, :updated_at
json.cost @recipe.cost.to_f
json.tag_names @recipe.tag_names
json.instructions @recipe.instructions.body.to_plain_text
json.url recipe_url(@recipe.slug)

json.image do
  json.url url_for(@recipe.image) if @recipe.image.attached?
end

json.images @recipe.images do |image|
  json.url url_for(image)
end

json.author do
  json.extract! @recipe.author, :id, :username, :email
end

json.category do
  json.extract! @recipe.category, :id, :title, :slug, :description
end
