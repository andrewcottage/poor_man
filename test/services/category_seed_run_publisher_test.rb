require "test_helper"

class CategorySeedRunPublisherTest < ActiveSupport::TestCase
  test "publishes a category seed run into a live category" do
    category_seed_run = category_seed_runs(:one)
    category_seed_run.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "weeknight-pasta.jpg",
      content_type: "image/jpeg"
    )

    category = CategorySeedRunPublisher.new(category_seed_run).call

    assert_equal "Weeknight Pasta", category.title
    assert_equal "weeknight-pasta", category.slug
    assert category.image.attached?
    assert_equal category, category_seed_run.reload.published_category
  end
end
