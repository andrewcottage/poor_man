# == Schema Information
#
# Table name: grocery_list_items
#
#  id              :integer          not null, primary key
#  aisle           :string           default("Pantry"), not null
#  checked         :boolean          default(FALSE), not null
#  name            :string           not null
#  notes           :string
#  position        :integer          default(1), not null
#  quantity        :string
#  unit            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grocery_list_id :integer          not null
#
# Indexes
#
#  index_grocery_list_items_on_grocery_list_id  (grocery_list_id)
#  index_grocery_list_items_on_grouping         (grocery_list_id,aisle,position)
#
# Foreign Keys
#
#  grocery_list_id  (grocery_list_id => grocery_lists.id)
#
class GroceryListItem < ApplicationRecord
  belongs_to :grocery_list

  validates :name, :aisle, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  scope :unchecked_first, -> { order(:checked, :aisle, :position, :id) }

  def display_text
    [
      quantity.presence,
      unit.presence,
      name
    ].compact.join(" ")
  end
end
