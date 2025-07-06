json.id @generation.id
json.prompt @generation.prompt
json.data @generation.data
json.complete @generation.complete?
json.created_at @generation.created_at
json.updated_at @generation.updated_at

json.has_image @generation.image.attached?
json.has_images @generation.images.attached?

if @generation.image.attached?
  json.image_url url_for(@generation.image)
end

if @generation.images.attached?
  json.images @generation.images do |image|
    json.url url_for(image)
  end
end 