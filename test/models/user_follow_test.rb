# == Schema Information
#
# Table name: user_follows
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  followed_id :integer          not null
#  follower_id :integer          not null
#
# Indexes
#
#  index_user_follows_on_followed_id                  (followed_id)
#  index_user_follows_on_follower_id                  (follower_id)
#  index_user_follows_on_follower_id_and_followed_id  (follower_id,followed_id) UNIQUE
#
# Foreign Keys
#
#  followed_id  (followed_id => users.id)
#  follower_id  (follower_id => users.id)
#
require "test_helper"

class UserFollowTest < ActiveSupport::TestCase
  test "does not allow following yourself" do
    user = users(:user)
    follow = UserFollow.new(follower: user, followed: user)

    assert_not follow.valid?
    assert_includes follow.errors[:followed_id], "cannot be the same as the follower"
  end
end
