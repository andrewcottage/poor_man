# == Schema Information
#
# Table name: category_seed_runs
#
#  id                    :integer          not null, primary key
#  data                  :text
#  prompt                :text             not null
#  published_at          :datetime
#  seed_publish_error    :text
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  published_category_id :integer
#  user_id               :integer          not null
#
# Indexes
#
#  index_category_seed_runs_on_published_category_id  (published_category_id)
#  index_category_seed_runs_on_user_id                (user_id)
#
# Foreign Keys
#
#  published_category_id  (published_category_id => categories.id)
#  user_id                (user_id => users.id)
#
class CategorySeedRun < ApplicationRecord
  serialize :data, coder: JSON, default: {}

  belongs_to :user
  belongs_to :published_category, class_name: "Category", optional: true

  has_one_attached :image

  validates :prompt, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def complete?
    data.present? && image.attached?
  end
end
