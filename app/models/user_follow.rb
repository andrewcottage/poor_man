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
class UserFollow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :prevent_self_follow

  private

  def prevent_self_follow
    return unless follower_id.present? && follower_id == followed_id

    errors.add(:followed_id, "cannot be the same as the follower")
  end
end
