class FamilyCookbook < ApplicationRecord
  belongs_to :family
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  has_many :family_cookbook_recipes, dependent: :destroy
  has_many :recipes, through: :family_cookbook_recipes

  validates :name, presence: true, uniqueness: { scope: :family_id }
end
