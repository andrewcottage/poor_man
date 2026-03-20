# == Schema Information
#
# Table name: chat_messages
#
#  id              :integer          not null, primary key
#  content         :text
#  role            :string           not null
#  tool_calls      :text
#  tool_name       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :integer          not null
#  tool_call_id    :string
#
# Indexes
#
#  index_chat_messages_on_conversation_id  (conversation_id)
#
# Foreign Keys
#
#  conversation_id  (conversation_id => chat_conversations.id)
#
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

  test "image only message is valid" do
    message = Chat::Message.new(conversation: chat_conversations(:pro_conversation), role: "user")
    message.images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "dinner.jpg",
      content_type: "image/jpeg"
    )

    assert message.valid?
  end

  test "blank message without images is invalid" do
    message = Chat::Message.new(conversation: chat_conversations(:pro_conversation), role: "user", content: "")

    assert_not message.valid?
    assert_includes message.errors.full_messages, "Message can't be blank"
  end

  test "api_content includes image parts for user uploads" do
    message = Chat::Message.create!(
      conversation: chat_conversations(:pro_conversation),
      role: "user",
      content: "What did I make?"
    )
    message.images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "dinner.jpg",
      content_type: "image/jpeg"
    )
    message.reload

    content = message.api_content

    assert_kind_of Array, content
    assert_equal "text", content.first[:type]
    assert_equal "image_url", content.second[:type]
    assert_match(/\Adata:image\/jpeg;base64,/, content.second.dig(:image_url, :url))
  end
end
