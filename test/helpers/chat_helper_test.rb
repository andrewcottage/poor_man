require "test_helper"

class ChatHelperTest < ActionView::TestCase
  include ChatHelper

  test "render_markdown converts markdown images to img tags" do
    html = render_markdown("Preview image:\n\n![](\/rails\/active_storage\/blobs\/redirect\/abc123\/preview.jpg)")

    assert_includes html, '<img src="/rails/active_storage/blobs/redirect/abc123/preview.jpg" alt="" loading="lazy" class="chat-preview-image" />'
  end

  test "render_markdown still converts markdown links" do
    html = render_markdown("[View Preview](/admin/seed_categories/1)")

    assert_includes html, '<a href="/admin/seed_categories/1">View Preview</a>'
  end

  test "render_markdown converts ordered lists for preview summaries" do
    html = render_markdown("1. Breakfast\n2. Dinner")

    assert_includes html, "<ol>"
    assert_includes html, "<li>Breakfast</li>"
    assert_includes html, "<li>Dinner</li>"
  end
end
