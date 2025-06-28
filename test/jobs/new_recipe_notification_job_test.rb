require "test_helper"

class NewRecipeNotificationJobTest < ActiveJob::TestCase
  test "should send notifications to users who opted in" do
    user_with_notifications = users(:one)
    user_with_notifications.update(notify_new_recipes: true)
    
    user_without_notifications = users(:two)
    user_without_notifications.update(notify_new_recipes: false)
    
    recipe = recipes(:one)
    
    assert_emails 1 do
      NewRecipeNotificationJob.perform_now(recipe.id)
    end
  end

  test "should not send notification to recipe author" do
    author = users(:one)
    author.update(notify_new_recipes: true)
    
    recipe = recipes(:one)
    recipe.update(author: author)
    
    assert_emails 0 do
      NewRecipeNotificationJob.perform_now(recipe.id)
    end
  end

  test "should enqueue job when recipe is created" do
    assert_enqueued_with(job: NewRecipeNotificationJob) do
      Recipe.create!(
        title: "Test Recipe",
        slug: "test-recipe-#{SecureRandom.hex(4)}",
        instructions: "Test instructions",
        blurb: "Test blurb",
        category: categories(:one),
        author: users(:one)
      )
    end
  end
end