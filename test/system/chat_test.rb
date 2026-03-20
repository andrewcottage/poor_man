require "application_system_test_case"

class ChatTest < ApplicationSystemTestCase
  test "anonymous user sees chat page with input form" do
    visit chat_url
    assert_selector "h1", text: "Recipe Chat"
    assert_selector "textarea[name='content']"
    assert_selector "button[type='submit']"
  end

  test "anonymous user sees suggestion buttons" do
    visit chat_url
    assert_selector "button", text: "What's trending right now?"
    assert_selector "button", text: "Easy weeknight dinners"
  end

  test "anonymous user submitting a message is redirected to login" do
    visit chat_url
    assert_selector "textarea[name='content']"

    fill_in "content", with: "What should I cook tonight?"
    find("button[type='submit']").click

    assert_selector "h2", text: "Sign in to your account", wait: 5
  end

  test "free user sees upgrade CTA" do
    skip "JS system driver unavailable" unless js_system_tests_enabled?

    sign_in_as(users(:user))
    visit chat_url
    assert_text "Recipe Chat is a Pro feature", wait: 5
  end

  test "pro user sees full chat interface" do
    skip "JS system driver unavailable" unless js_system_tests_enabled?

    sign_in_as(users(:pro_user))
    visit chat_url
    assert_selector "h1", text: "Recipe Chat"
    assert_selector "textarea[name='content']"
    assert_selector "#chat_messages"
  end

  test "pro user can type and submit a message" do
    skip "JS system driver unavailable" unless js_system_tests_enabled?

    sign_in_as(users(:pro_user))
    visit chat_url
    assert_selector "textarea[name='content']"

    fill_in "content", with: "Find me easy pasta recipes"
    find("button[type='submit']").click

    assert_text "Find me easy pasta recipes", wait: 5
  end

  test "admin sees seed copilot empty state" do
    skip "JS system driver unavailable" unless js_system_tests_enabled?

    sign_in_as(users(:admin))
    visit chat_url

    assert_selector "h1", text: "Seed Copilot"
    assert_text "What should I create?"
    assert_selector "button", text: "Preview a vegan sheet-pan dinner with crispy tofu and chili crisp."
  end

  test "admin can generate a seed preview from chat" do
    skip "JS system driver unavailable" unless js_system_tests_enabled?

    sign_in_as(users(:admin))

    stub_openai_chat_responses(
      {
        "role" => "assistant",
        "content" => "",
        "tool_calls" => [
          {
            "id" => "call_seed_preview",
            "type" => "function",
            "function" => {
              "name" => "preview_seed_recipe",
              "arguments" => {
                prompt: "Preview a vegan grain bowl for the site",
                dietary_preference: "vegan",
                publish_immediately: false
              }.to_json
            }
          }
        ]
      },
      {
        "role" => "assistant",
        "content" => {
          title: "Roasted Cauliflower Grain Bowl",
          blurb: "A hearty bowl with roasted vegetables and tahini dressing.",
          ingredients: [
            { quantity: "1", unit: "head", name: "cauliflower" },
            { quantity: "1", unit: "cup", name: "farro" }
          ],
          instructions: "<p>Roast the cauliflower.</p><p>Cook the farro.</p>",
          tags: %w[vegan grain-bowl],
          difficulty: 2,
          prep_time: 35,
          cost: 14.5,
          servings: 4,
          category: "Grain Bowls"
        }.to_json
      },
      {
        "role" => "assistant",
        "content" => "Preview ready. I created a photorealistic preview for Roasted Cauliflower Grain Bowl."
      }
    )
    stub_openai_image_generation_sequence(count: 4, prefix: "roasted-cauliflower-grain-bowl")

    visit chat_url

    perform_enqueued_jobs do
      fill_in "content", with: "Preview a vegan grain bowl for the site"
      find("button[type='submit']").click
      assert_text "Preview a vegan grain bowl for the site", wait: 5
      assert_text "Preview ready. I created a photorealistic preview for Roasted Cauliflower Grain Bowl.", wait: 5
    end

    generation = Recipe::Generation.seed_runs.order(created_at: :desc).first
    assert_equal "Roasted Cauliflower Grain Bowl", generation.data["title"]
    assert generation.image.attached?
    assert_equal 3, generation.images.count
  end
end
