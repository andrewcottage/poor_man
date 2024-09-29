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
    instructions: Faker::Lorem.paragraph(sentence_count: 4),
    blurb: Faker::Lorem.paragraph(sentence_count: 2),
    content: Faker::Lorem.paragraph(sentence_count: 4),
    slug: SecureRandom.uuid,
    image: {io: File.open(image), filename: "image.jpg"},
    category: Category.all.sample,
  )
end

user = User.create!(
  username: "admin",
  email: "admin@poormanwithapan.com",
  password: "password"
)


other_users = []

5.times do |i|
  other_users << User.create!(
    username: "user_#{i}",
    email: "user_#{i}@gmail.com",
    password: "password"
  )
end

Recipe.find_each do |recipe|
  recipe.ratings.create!(
    user: user,
    value: (1..5).to_a.sample,
    title: Faker::Lorem.paragraph(sentence_count: 1),
    comment: Faker::Lorem.paragraph(sentence_count: 3)
  )

  other_users.each do |user|
    recipe.ratings.create!(
      user: user,
      value: (1..5).to_a.sample,
      title: Faker::Lorem.paragraph(sentence_count: 1),
      comment: Faker::Lorem.paragraph(sentence_count: 3)
    )
  end
end