# == Schema Information
#
# Table name: pro_waitlist_entries
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  plan_preference :string
#  source          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer
#
# Indexes
#
#  index_pro_waitlist_entries_on_email    (email) UNIQUE
#  index_pro_waitlist_entries_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class ProWaitlistEntry < ApplicationRecord
  PLAN_OPTIONS = %w[monthly annual].freeze

  belongs_to :user, optional: true

  normalizes :email, with: ->(email) { email.to_s.downcase.strip }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :plan_preference, inclusion: { in: PLAN_OPTIONS }, allow_blank: true

  after_create_commit :track_signup

  private

  def track_signup
    AnalyticsEvent.record!(
      event_name: "pricing.waitlist_joined",
      user: user,
      path: "/pricing",
      metadata: {
        email: email,
        source: source,
        plan_preference: plan_preference
      }.compact
    )
  end
end
