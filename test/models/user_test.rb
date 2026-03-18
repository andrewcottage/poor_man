# == Schema Information
#
# Table name: users
#
#  id                         :integer          not null, primary key
#  admin                      :boolean
#  api_key                    :string
#  email                      :string           not null
#  free_generation_used_at    :datetime
#  generation_credits_balance :integer          default(0), not null
#  generations_count          :integer          default(0), not null
#  generations_reset_at       :datetime
#  name                       :string
#  password_digest            :string
#  plan                       :string           default("free"), not null
#  plan_expires_at            :datetime
#  provider                   :string
#  recovery_digest            :string
#  uid                        :string
#  username                   :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  stripe_customer_id         :string
#  stripe_subscription_id     :string
#
# Indexes
#
#  index_users_on_api_key                 (api_key) UNIQUE
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_plan                    (plan)
#  index_users_on_stripe_customer_id      (stripe_customer_id)
#  index_users_on_stripe_subscription_id  (stripe_subscription_id)
#  index_users_on_username                (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "free user gets one lifetime generation trial" do
    user = users(:user)

    assert_equal 1, user.remaining_recipe_generations

    user.update!(free_generation_used_at: Time.current, generations_count: 1)

    assert_equal 0, user.remaining_recipe_generations
  end

  test "pro user has monthly generation allowance" do
    user = users(:pro_user)

    assert user.pro?
    assert_equal 11, user.remaining_recipe_generations
  end

  test "consuming a pro generation increments count" do
    user = users(:pro_user)

    assert user.consume_recipe_generation!

    user.reload
    assert_equal 5, user.generations_count
  end

  test "consuming generation uses credit balance after included allowance is exhausted" do
    user = users(:user)
    user.update!(free_generation_used_at: Time.current, generations_count: 1, generation_credits_balance: 2)

    assert user.consume_recipe_generation!

    user.reload
    assert_equal 1, user.generation_credits_balance
    assert_equal 1, user.generations_count
  end

  test "free collection limit is enforced" do
    user = users(:user)

    assert_not user.can_create_collection?
  end

  test "contributor badge reflects community reputation" do
    user = users(:user)

    assert_equal "Community Cook", user.contributor_badge
  end

  test "username defaults from email when blank" do
    user = User.new(email: "hello@example.com", password: "password", password_confirmation: "password")

    user.valid?

    assert_equal "hello", user.username
  end
end
