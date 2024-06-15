# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# generate 25 categories

names = [
  "Breakfast",
  "Lunch",
  "Dinner",
  "Dessert",
  "Snack",
  "Appetizer",
  "Main Course",
  "Side Dish",
  "Salad",
  "Soup",
  "Stew",
  "Beverage",
  "Bread",
  "Sandwich",
  "Pizza",
  "Pasta",
  "Rice",
  "Noodle",
  "Curry"
]

names.each_with_index do |name, i|
  image = Dir.glob("db/seeds/images/category/*").sample

  Category.create!(
    title: name,
    description: "This is the description for category #{i}",
    slug: SecureRandom.uuid,
    image: {io: File.open(image), filename: "image.jpg"},
  )
end

# generate hundreds of recipes
100.times do |i|
  image = Dir.glob("db/seeds/images/food/*").sample

  Recipe.create!(
    title: "Recipe #{i}",
    content: "This is the content for recipe #{i}",
    slug: SecureRandom.uuid,
    image: {io: File.open(image), filename: "image.jpg"},
    category: Category.all.sample,
  )
end

