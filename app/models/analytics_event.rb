# == Schema Information
#
# Table name: analytics_events
#
#  id         :integer          not null, primary key
#  event_name :string           not null
#  metadata   :text
#  path       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_analytics_events_on_created_at  (created_at)
#  index_analytics_events_on_event_name  (event_name)
#  index_analytics_events_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class AnalyticsEvent < ApplicationRecord
  belongs_to :user, optional: true

  serialize :metadata, coder: JSON, default: {}

  validates :event_name, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(event_name:, user: nil, path: nil, metadata: {})
    create!(
      event_name: event_name,
      user: user,
      path: path,
      metadata: metadata
    )
  end
end
