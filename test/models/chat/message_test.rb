require "test_helper"

class Chat::MessageTest < ActiveSupport::TestCase
  test "belongs to conversation" do
    message = chat_messages(:user_message)
    assert_equal chat_conversations(:pro_conversation), message.conversation
  end

  test "requires role" do
    message = Chat::Message.new(conversation: chat_conversations(:pro_conversation), content: "test")
    assert_not message.valid?
    assert_includes message.errors[:role], "can't be blank"
  end

  test "validates role inclusion" do
    message = Chat::Message.new(
      conversation: chat_conversations(:pro_conversation),
      role: "invalid",
      content: "test"
    )
    assert_not message.valid?
    assert_includes message.errors[:role], "is not included in the list"
  end

  test "visible scope returns only user and assistant messages" do
    conversation = chat_conversations(:pro_conversation)
    conversation.messages.create!(role: "tool", content: "tool result", tool_call_id: "123", tool_name: "test")
    visible = conversation.messages.visible
    assert visible.all? { |m| %w[user assistant].include?(m.role) }
  end

  test "user? and assistant? predicates" do
    assert chat_messages(:user_message).user?
    assert_not chat_messages(:user_message).assistant?
    assert chat_messages(:assistant_message).assistant?
    assert_not chat_messages(:assistant_message).user?
  end
end
