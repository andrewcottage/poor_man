# == Schema Information
#
# Table name: meal_plans
#
#  id         :integer          not null, primary key
#  week_of    :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_meal_plans_on_user_id              (user_id)
#  index_meal_plans_on_user_id_and_week_of  (user_id,week_of) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class MealPlan < ApplicationRecord
  MEAL_TYPES = %w[breakfast lunch dinner snack].freeze

  belongs_to :user
  has_many :planned_meals, -> { order(:scheduled_on, :meal_type, :position, :id) }, dependent: :destroy
  has_many :recipes, through: :planned_meals
  has_one :grocery_list, dependent: :destroy

  before_validation :normalize_week_of

  validates :week_of, presence: true, uniqueness: { scope: :user_id }

  scope :recent_first, -> { order(week_of: :desc) }

  def self.for_week(user:, week_of:)
    normalized_week = normalize_week(week_of)
    user.meal_plans.find_or_create_by!(week_of: normalized_week)
  end

  def self.normalize_week(value)
    parsed = value.is_a?(Date) ? value : Date.parse(value.to_s)
    parsed.beginning_of_week(:monday)
  rescue ArgumentError, TypeError
    Date.current.beginning_of_week(:monday)
  end

  def days
    (week_of..(week_of + 6.days)).to_a
  end

  def title
    "Week of #{I18n.l(week_of, format: :long)}"
  end

  def planned_meals_for(day)
    planned_meals.select { |planned_meal| planned_meal.scheduled_on == day }
  end

  private

  def normalize_week_of
    self.week_of = self.class.normalize_week(week_of)
  end
end
