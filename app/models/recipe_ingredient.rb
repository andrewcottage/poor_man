# == Schema Information
#
# Table name: recipe_ingredients
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  notes      :string
#  position   :integer          default(1), not null
#  quantity   :string
#  raw        :text             not null
#  unit       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#
# Indexes
#
#  index_recipe_ingredients_on_recipe_id               (recipe_id)
#  index_recipe_ingredients_on_recipe_id_and_position  (recipe_id,position)
#
# Foreign Keys
#
#  recipe_id  (recipe_id => recipes.id)
#
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe

  validates :name, :raw, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  scope :ordered, -> { order(:position, :id) }

  def display_text
    text = [
      quantity.presence,
      unit.presence,
      name.presence
    ].compact.join(" ")

    return text if notes.blank?

    "#{text}, #{notes}"
  end

  def as_structured_json
    {
      quantity: quantity,
      unit: unit,
      name: name,
      notes: notes,
      raw: raw
    }.compact
  end
end
