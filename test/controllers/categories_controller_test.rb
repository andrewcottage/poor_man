require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login
    @category = categories(:one)
  end

  test "should get index" do
    get categories_url
    assert_response :success
  end

  test "should get new" do
    get new_category_url
    assert_response :success
  end

  test "should create category" do
    assert_difference("Category.count") do
      post categories_url, params: { category: { description: Faker::Lorem.sentence, title: SecureRandom.uuid, image: fixture_file_upload('vaporwave.jpeg', 'image/jpg'), slug: SecureRandom.uuid } }
    end

    assert_redirected_to category_url(Category.last.slug)
  end

  test "should show category" do
    get category_url(@category)
    assert_response :success
  end

  test "should get edit" do
    get edit_category_url(@category)
    assert_response :success
  end

  test "should update category" do
    patch category_url(@category), params: { category: { title: SecureRandom.uuid, image: fixture_file_upload('vaporwave.jpeg', 'image/jpg') } }
    assert_redirected_to category_url(@category.slug)
  end

  test "should destroy category" do
    assert_difference("Category.count", -1) do
      delete category_url(categories(:deleteable))
    end

    assert_redirected_to categories_url
  end
end
