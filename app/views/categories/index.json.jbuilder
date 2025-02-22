json.array! @categories do |category|
  json.id category.id
  json.slug category.slug
  json.name category.title
  json.description category.description
  json.image url_for(category.image)
  json.created_at category.created_at
  json.updated_at category.updated_at
end