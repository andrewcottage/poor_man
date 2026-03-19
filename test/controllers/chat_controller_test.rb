require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user to login" do
    get chat_url
    assert_redirected_to new_session_path
  end

  test "pro user can access chat" do
    login(users(:pro_user))
    get chat_url
    assert_response :success
    assert_select "[data-controller='chat']"
  end

  test "free user sees upgrade CTA" do
    login(users(:user))
    get chat_url
    assert_response :success
    assert_select "a[href='#{pricing_path}']", text: /Upgrade/
  end

  test "pro user can send a message" do
    login(users(:pro_user))

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url, params: { content: "What should I cook tonight?" }, as: :turbo_stream
    end

    assert_response :success
    conversation = users(:pro_user).chat_conversations.last
    assert_equal "What should I cook tonight?", conversation.messages.where(role: "user").last.content
  end

  test "free user cannot send messages" do
    login(users(:user))
    post create_message_chat_url, params: { content: "test" }
    assert_redirected_to pricing_path
  end
end
