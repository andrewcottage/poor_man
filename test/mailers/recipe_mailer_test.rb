require "test_helper"

class RecipeMailerTest < ActionMailer::TestCase
  test "new recipe notification" do
    user = users(:one)
    recipe = recipes(:one)
    
    email = RecipeMailer.new_recipe_notification(user, recipe)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ['notifications@poorman.com'], email.from
    assert_equal [user.email], email.to
    assert_equal "New Recipe Added: #{recipe.title}", email.subject
    assert_match recipe.title, email.body.to_s
    assert_match user.username, email.body.to_s
  end
end