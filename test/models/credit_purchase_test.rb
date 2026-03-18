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
require "test_helper"

class CreditPurchaseTest < ActiveSupport::TestCase
  test "apply_to_user credits balance once" do
    user = users(:user)
    user.update!(generation_credits_balance: 0)
    purchase = user.credit_purchases.create!(pack_id: "extra_5", credits: 5, status: :paid)

    purchase.apply_to_user!
    purchase.apply_to_user!

    user.reload
    purchase.reload
    assert_equal 5, user.generation_credits_balance
    assert purchase.credited_at.present?
  end
end
