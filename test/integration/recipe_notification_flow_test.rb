require "test_helper"

class RecipeNotificationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update(notify_new_recipes: true)
    
    @author = users(:two)
    @category = categories(:one)
  end

  test "user can update notification preferences" do
    post sessions_path, params: { email: @user.email, password: 'secret' }
    
    get edit_profile_path
    assert_response :success
    assert_select 'input[name="profile[notify_new_recipes]"]'
    
    patch profile_path, params: {
      profile: {
        notify_new_recipes: false
      }
    }
    
    assert_redirected_to profile_path
    @user.reload
    assert_not @user.notify_new_recipes
  end

  test "notifications are sent when new recipe is created" do
    post sessions_path, params: { email: @author.email, password: 'secret' }
    
    assert_enqueued_jobs 1, only: NewRecipeNotificationJob do
      post recipes_path, params: {
        recipe: {
          title: "New Test Recipe",
          slug: "new-test-recipe-#{SecureRandom.hex(4)}",
          instructions: "Test instructions",
          blurb: "Test blurb",
          category_id: @category.id
        }
      }
    end
    
    assert_response :redirect
  end

  test "user opts out of notifications" do
    post sessions_path, params: { email: @user.email, password: 'secret' }
    
    patch profile_path, params: {
      profile: {
        notify_new_recipes: false
      }
    }
    
    @user.reload
    assert_not @user.notify_new_recipes
    
    # Create a recipe as another user
    recipe = Recipe.create!(
      title: "Test Recipe",
      slug: "test-recipe-#{SecureRandom.hex(4)}",
      instructions: "Test instructions",
      blurb: "Test blurb",
      category: @category,
      author: @author
    )
    
    assert_emails 0 do
      NewRecipeNotificationJob.perform_now(recipe.id)
    end
  end
end