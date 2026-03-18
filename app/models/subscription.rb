# == Schema Information
#
# Table name: subscriptions
#
#  id                         :integer          not null, primary key
#  canceled_at                :datetime
#  current_period_end         :datetime
#  payload                    :text
#  plan                       :string           not null
#  status                     :string           default("pending"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  stripe_checkout_session_id :string
#  stripe_customer_id         :string
#  stripe_price_id            :string
#  stripe_subscription_id     :string
#  user_id                    :integer          not null
#
# Indexes
#
#  index_subscriptions_on_plan                        (plan)
#  index_subscriptions_on_status                      (status)
#  index_subscriptions_on_stripe_checkout_session_id  (stripe_checkout_session_id) UNIQUE
#  index_subscriptions_on_stripe_customer_id          (stripe_customer_id)
#  index_subscriptions_on_stripe_subscription_id      (stripe_subscription_id)
#  index_subscriptions_on_user_id                     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Subscription < ApplicationRecord
  ACTIVE_STATUSES = %w[active past_due].freeze

  belongs_to :user

  serialize :payload, coder: JSON, default: {}

  enum :plan, {
    pan_pro_monthly: User::PLAN_PRO_MONTHLY,
    pan_pro_annual: User::PLAN_PRO_ANNUAL
  }, validate: true

  enum :status, {
    pending: "pending",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    incomplete: "incomplete"
  }, validate: true

  validates :stripe_checkout_session_id, uniqueness: true, allow_blank: true
  validates :stripe_subscription_id, uniqueness: true, allow_blank: true

  scope :recent_first, -> { order(created_at: :desc) }

  def active_access?
    status.in?(ACTIVE_STATUSES)
  end

  def apply_to_user!
    if active_access?
      user.update!(
        plan: plan,
        stripe_customer_id: stripe_customer_id.presence || user.stripe_customer_id,
        stripe_subscription_id: stripe_subscription_id.presence || user.stripe_subscription_id,
        plan_expires_at: current_period_end,
        generations_count: 0,
        generations_reset_at: 1.month.from_now
      )
    else
      user.update!(
        plan: User::PLAN_FREE,
        stripe_subscription_id: nil,
        plan_expires_at: nil,
        generations_count: 0,
        generations_reset_at: nil
      )
    end
  end

  def self.sync_from_checkout_session!(session_data)
    user = User.find_by(id: session_data["client_reference_id"] || session_data.dig("metadata", "user_id"))
    return if user.blank?

    subscription = user.subscriptions.find_or_initialize_by(stripe_checkout_session_id: session_data["id"])
    subscription.assign_attributes(
      plan: session_data.dig("metadata", "plan") || User::PLAN_PRO_MONTHLY,
      status: "pending",
      stripe_checkout_session_id: session_data["id"],
      stripe_customer_id: session_data["customer"],
      stripe_subscription_id: session_data["subscription"],
      stripe_price_id: session_data.dig("metadata", "price_id"),
      payload: session_data
    )
    subscription.save!

    user.update!(stripe_customer_id: session_data["customer"]) if session_data["customer"].present?
    subscription
  end

  def self.sync_from_stripe_subscription!(subscription_data)
    customer_id = subscription_data["customer"]
    user = User.find_by(stripe_customer_id: customer_id) || User.find_by(id: subscription_data.dig("metadata", "user_id"))
    return if user.blank?

    subscription = user.subscriptions.find_or_initialize_by(stripe_subscription_id: subscription_data["id"])
    subscription.assign_attributes(
      plan: plan_from(subscription_data),
      status: normalized_status(subscription_data["status"]),
      stripe_customer_id: customer_id,
      stripe_subscription_id: subscription_data["id"],
      stripe_price_id: subscription_data.dig("items", "data", 0, "price", "id"),
      current_period_end: timestamp_for(subscription_data["current_period_end"]),
      canceled_at: timestamp_for(subscription_data["canceled_at"]),
      payload: subscription_data
    )
    subscription.save!
    subscription.apply_to_user!
    subscription
  end

  def self.plan_from(subscription_data)
    Billing::Config.plan_from_price_id(subscription_data.dig("items", "data", 0, "price", "id")) ||
      subscription_data.dig("metadata", "plan") ||
      User::PLAN_PRO_MONTHLY
  end

  def self.normalized_status(stripe_status)
    return "active" if stripe_status == "trialing"
    return stripe_status if statuses.key?(stripe_status)

    "pending"
  end

  def self.timestamp_for(unix_timestamp)
    return if unix_timestamp.blank?

    Time.zone.at(unix_timestamp)
  end
end
