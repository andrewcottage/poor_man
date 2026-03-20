require "test_helper"

class Admin::SeedCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @category_seed_run = category_seed_runs(:one)
    @category_seed_run.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "weeknight-pasta.jpg",
      content_type: "image/jpeg"
    )
  end

  test "admin can view category seed runs" do
    login(@admin)

    get admin_seed_categories_path

    assert_response :success
    assert_includes response.body, "Category Seed Runs"
  end

  test "admin can publish a category seed run" do
    login(@admin)

    post publish_admin_seed_category_path(@category_seed_run)

    assert_redirected_to admin_seed_category_path(@category_seed_run)
    assert @category_seed_run.reload.published_category.present?
    assert_equal "Weeknight Pasta", @category_seed_run.published_category.title
  end
end
