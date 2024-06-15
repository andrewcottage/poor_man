json.extract! category, :id, :name, :slug, :description, :recipies_count, :created_at, :updated_at
json.url category_url(category, format: :json)
