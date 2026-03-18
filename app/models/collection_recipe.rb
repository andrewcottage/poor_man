# == Schema Information
#
# Table name: collection_recipes
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer          not null
#  recipe_id     :integer          not null
#
# Indexes
#
#  index_collection_recipes_on_collection_id                (collection_id)
#  index_collection_recipes_on_collection_id_and_recipe_id  (collection_id,recipe_id) UNIQUE
#  index_collection_recipes_on_recipe_id                    (recipe_id)
#
# Foreign Keys
#
#  collection_id  (collection_id => collections.id)
#  recipe_id      (recipe_id => recipes.id)
#
class CollectionRecipe < ApplicationRecord
  belongs_to :collection
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :collection_id }
end
