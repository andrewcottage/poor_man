# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  admin           :boolean
#  api_key         :string
#  email           :string           not null
#  name            :string
#  password_digest :string
#  provider        :string
#  recovery_digest :string
#  uid             :string
#  username        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_api_key   (api_key) UNIQUE
#  index_users_on_email     (email) UNIQUE
#  index_users_on_username  (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user should have notify_new_recipes enabled by default" do
    user = User.new(email: "test@example.com", username: "testuser", password: "password")
    assert user.notify_new_recipes
  end

  test "user can opt out of new recipe notifications" do
    user = users(:one)
    user.update(notify_new_recipes: false)
    assert_not user.notify_new_recipes
  end
end
