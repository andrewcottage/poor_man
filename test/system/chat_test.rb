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
    sign_in_as(users(:user))
    visit chat_url
    assert_text "Recipe Chat is a Pro feature", wait: 5
  end

  test "pro user sees full chat interface" do
    sign_in_as(users(:pro_user))
    visit chat_url
    assert_selector "h1", text: "Recipe Chat"
    assert_selector "textarea[name='content']"
    assert_selector "#chat_messages"
  end

  test "pro user can type and submit a message" do
    sign_in_as(users(:pro_user))
    visit chat_url
    assert_selector "textarea[name='content']"

    fill_in "content", with: "Find me easy pasta recipes"
    find("button[type='submit']").click

    assert_text "Find me easy pasta recipes", wait: 5
  end
end
