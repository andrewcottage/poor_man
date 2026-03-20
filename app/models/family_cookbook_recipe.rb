class FamilyCookbookRecipe < ApplicationRecord
  belongs_to :family_cookbook
  belongs_to :recipe
  belongs_to :contributor, class_name: "User", foreign_key: :added_by

  validates :recipe_id, uniqueness: { scope: :family_cookbook_id, message: "is already in this cookbook" }
end
