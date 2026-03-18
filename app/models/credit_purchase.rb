# == Schema Information
#
# Table name: credit_purchases
#
#  id                         :integer          not null, primary key
#  credited_at                :datetime
#  credits                    :integer          not null
#  payload                    :text
#  status                     :integer          default("pending"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  pack_id                    :string           not null
#  stripe_checkout_session_id :string
#  stripe_customer_id         :string
#  stripe_payment_intent_id   :string
#  stripe_price_id            :string
#  user_id                    :integer          not null
#
# Indexes
#
#  index_credit_purchases_on_pack_id                     (pack_id)
#  index_credit_purchases_on_stripe_checkout_session_id  (stripe_checkout_session_id) UNIQUE
#  index_credit_purchases_on_stripe_payment_intent_id    (stripe_payment_intent_id)
#  index_credit_purchases_on_user_id                     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class CreditPurchase < ApplicationRecord
  belongs_to :user

  serialize :payload, coder: JSON, default: {}

  enum :status, {
    pending: 0,
    paid: 1,
    refunded: 2
  }, validate: true

  validates :pack_id, :credits, presence: true
  validates :credits, numericality: { only_integer: true, greater_than: 0 }
  validates :stripe_checkout_session_id, uniqueness: true, allow_blank: true

  scope :recent_first, -> { order(created_at: :desc) }

  def apply_to_user!
    return unless paid?
    return if credited_at.present?

    transaction do
      user.with_lock do
        user.update!(generation_credits_balance: user.generation_credits_balance + credits)
      end

      update!(credited_at: Time.current)
    end
  end

  def self.sync_from_checkout_session!(session_data)
    return unless session_data.dig("metadata", "kind") == "credit_pack"

    pack_id = session_data.dig("metadata", "pack_id")
    pack = Billing::PlanCatalog.credit_pack(pack_id)
    return if pack.blank?

    user = User.find_by(id: session_data["client_reference_id"] || session_data.dig("metadata", "user_id"))
    return if user.blank?

    purchase = user.credit_purchases.find_or_initialize_by(stripe_checkout_session_id: session_data["id"])
    purchase.assign_attributes(
      pack_id: pack_id,
      credits: pack.fetch(:credits),
      status: :paid,
      stripe_checkout_session_id: session_data["id"],
      stripe_customer_id: session_data["customer"],
      stripe_payment_intent_id: session_data["payment_intent"],
      stripe_price_id: session_data.dig("metadata", "price_id"),
      payload: session_data
    )
    purchase.save!
    purchase.apply_to_user!
    purchase
  end
end
