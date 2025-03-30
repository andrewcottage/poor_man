require 'test_helper'

class RecapMailerTest < ActionMailer::TestCase
  test "monthly_recap" do
    user = users(:one)  # Assuming you have a user fixture
    
    # Create some test data for the past month
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    
    # Create test recipes and interactions
    recipe = Recipe.create!(
      user: user,
      title: "Test Recipe"
    )
    
    3.times { recipe.favorites.create!(user: users(:two)) }
    recipe.comments.create!(user: users(:two), content: "Great recipe!")
    recipe.ratings.create!(user: users(:two), value: 4)

    # Generate the email
    email = RecapMailer.monthly_recap(user)

    # Assert the email properties
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal "Your Monthly Recipe Recap for #{start_date.strftime('%B %Y')}", email.subject
    
    # Test email content
    assert_match "Hi #{user.name}", email.body.to_s
    assert_match "3 new favorites", email.body.to_s
    assert_match "1 comments", email.body.to_s
    assert_match "4.0 stars", email.body.to_s
  end
end 