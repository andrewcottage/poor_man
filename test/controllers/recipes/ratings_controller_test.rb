require "test_helper"

class Recipes::RatingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login
    @recipe = recipes(:pizza)
    @user = users(:andrew)
    # Remove any existing ratings from this user for this recipe
    Rating.where(user: @user, recipe: @recipe).destroy_all
  end
  
  test "should create rating" do
    assert_difference("Rating.count") do
      post recipe_ratings_url(@recipe), params: { 
        rating: { 
          value: 4,
          title: "Good recipe",
          comment: "I enjoyed making this recipe"
        } 
      }
    end
    
    assert_redirected_to recipe_url(@recipe.slug)
    
    # Check that the rating was created with the correct value
    rating = Rating.find_by(user: @user, recipe: @recipe)
    assert_equal 4, rating.value
  end
  
  test "should update rating if already exists" do
    # Create an initial rating
    rating = Rating.create!(
      user: @user, 
      recipe: @recipe, 
      value: 3,
      title: "Initial rating",
      comment: "My first impression"
    )
    
    # Set Current.user for the rating to be associated with the logged-in user
    Current.user = @user
    
    assert_no_difference("Rating.count") do
      patch recipe_rating_url(@recipe, rating), params: { 
        rating: { 
          value: 5,
          title: "Updated rating",
          comment: "After trying again, I loved it"
        } 
      }
    end
    
    assert_redirected_to recipe_url(@recipe.slug)
    
    # Check that the rating was updated
    rating.reload
    assert_equal 5, rating.value
  end
  
  test "should delete rating" do
    # Set Current.user to make sure authorization passes
    Current.user = @user

    # Create a rating to delete
    rating = Rating.create!(
      user: @user, 
      recipe: @recipe, 
      value: 3,
      title: "Rating to delete",
      comment: "Will be deleted"
    )
    
    assert_difference("Rating.count", -1) do
      delete recipe_rating_url(@recipe, rating)
    end
    
    assert_redirected_to recipe_url(@recipe.slug)
  end
end 