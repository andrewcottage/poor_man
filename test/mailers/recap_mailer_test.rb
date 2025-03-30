require 'test_helper'

class RecapMailerTest < ActionMailer::TestCase
  test "monthly_recap" do
    user = users(:andrew)
    start_date = 1.month.ago.beginning_of_month
    recipe = user.recipes.first
    
    recipe.favorites.create!(user: users(:victoria))
    recipe.ratings.create!(
      user: users(:victoria), 
      title: "Great recipe!", 
      comment: "Great recipe!", 
      value: 4
    )


    email = RecapMailer.monthly_recap(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal "Your Monthly Recipe Recap for #{start_date.strftime('%B %Y')}", email.subject
    
    assert_match "Hi #{user.name}", email.body.to_s
    assert_match "1 new favorites", email.body.to_s
    assert_match "1 comments", email.body.to_s
    assert_match "4.0 stars", email.body.to_s
  end
end 