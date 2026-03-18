# == Schema Information
#
# Table name: grocery_lists
#
#  id           :integer          not null, primary key
#  generated_at :datetime
#  share_token  :string           not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  meal_plan_id :integer          not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_grocery_lists_on_meal_plan_id  (meal_plan_id) UNIQUE
#  index_grocery_lists_on_share_token   (share_token) UNIQUE
#  index_grocery_lists_on_user_id       (user_id)
#
# Foreign Keys
#
#  meal_plan_id  (meal_plan_id => meal_plans.id)
#  user_id       (user_id => users.id)
#
class GroceryList < ApplicationRecord
  belongs_to :user
  belongs_to :meal_plan
  has_many :grocery_list_items, -> { order(:aisle, :position, :id) }, dependent: :destroy

  before_validation :ensure_share_token
  before_validation :ensure_title

  validates :title, :share_token, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def grouped_items
    grocery_list_items.group_by(&:aisle)
  end

  def regenerate!
    GroceryList::Builder.new(meal_plan: meal_plan).call
  end

  private

  def ensure_share_token
    return if share_token.present?

    self.share_token = loop do
      candidate = SecureRandom.hex(10)
      break candidate unless self.class.exists?(share_token: candidate)
    end
  end

  def ensure_title
    return if title.present?

    self.title = "#{meal_plan.title} groceries"
  end
end
