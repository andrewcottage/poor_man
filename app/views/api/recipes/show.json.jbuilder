json.extract! @recipe, :id, :title, :slug, :blurb, :difficulty, :prep_time, :servings, :created_at, :updated_at
json.cost @recipe.cost.to_f
json.tag_names @recipe.tag_names
json.instructions @recipe.instructions.body.to_plain_text
json.moderation_status @recipe.moderation_status
json.nutrition do
  json.available @recipe.nutrition_available?
  json.calories @recipe.nutrition_calories
  json.protein_grams @recipe.nutrition_protein_grams
  json.carbs_grams @recipe.nutrition_carbs_grams
  json.fat_grams @recipe.nutrition_fat_grams
  json.coverage_label @recipe.nutrition_coverage_label
end
json.ingredients @recipe.recipe_ingredients.ordered do |ingredient|
  json.extract! ingredient, :quantity, :unit, :name, :notes, :raw
end
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
