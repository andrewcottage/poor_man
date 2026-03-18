require "test_helper"

class CooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cook = users(:andrew)
    @recipe = recipes(:pizza)
    Rating.create!(user: users(:user), recipe: @recipe, value: 5, title: "Great", comment: "Would make again")
  end

  test "shows public cook profile" do
    get cook_url(@cook.username)

    assert_response :success
    assert_select "h1", text: @cook.username
    assert_select "h2", text: "Published recipes"
    assert_select "h3", text: @recipe.title
  end

  test "shows follow button for signed in users" do
    login(users(:user))

    get cook_url(@cook.username)

    assert_response :success
    assert_select "form[action='#{cook_follow_path(@cook.username)}']"
  end
end
