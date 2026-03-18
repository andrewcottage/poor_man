require "test_helper"

class Community::FeedTest < ActiveSupport::TestCase
  test "returns recent recipe and review activity" do
    rating = Rating.create!(
      user: users(:user),
      recipe: recipes(:pizza),
      value: 5,
      title: "Loved it",
      comment: "Would absolutely make again"
    )

    activities = Community::Feed.call(limit: 6)

    assert activities.any? { |activity| activity.type == :recipe && activity.recipe == recipes(:pizza) }
    assert activities.any? { |activity| activity.type == :review && activity.rating == rating }
  end
end
