# == Schema Information
#
# Table name: chat_conversations
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_chat_conversations_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "test_helper"

class Chat::ConversationTest < ActiveSupport::TestCase
  test "belongs to user" do
    conversation = chat_conversations(:pro_conversation)
    assert_equal users(:pro_user), conversation.user
  end

  test "has many messages" do
    conversation = chat_conversations(:pro_conversation)
    assert conversation.messages.count >= 2
  end

  test "destroying conversation destroys messages" do
    conversation = chat_conversations(:pro_conversation)
    message_count = conversation.messages.count
    assert_difference("Chat::Message.count", -message_count) do
      conversation.destroy
    end
  end

  test "messages_for_api returns formatted messages" do
    conversation = chat_conversations(:pro_conversation)
    api_messages = conversation.messages_for_api
    assert api_messages.all? { |m| m.key?(:role) && m.key?(:content) }
  end

  test "messages_for_api caps at MAX_API_MESSAGES" do
    conversation = chat_conversations(:pro_conversation)

    # Create more messages than the limit
    (Chat::Conversation::MAX_API_MESSAGES + 10).times do |i|
      conversation.messages.create!(role: "user", content: "Message #{i}")
    end

    api_messages = conversation.messages_for_api
    assert_operator api_messages.size, :<=, Chat::Conversation::MAX_API_MESSAGES
  end

  test "messages_for_api returns most recent messages when over limit" do
    conversation = chat_conversations(:pro_conversation)
    conversation.messages.destroy_all

    (Chat::Conversation::MAX_API_MESSAGES + 5).times do |i|
      conversation.messages.create!(role: "user", content: "Message #{i}")
    end

    api_messages = conversation.messages_for_api
    last_content = api_messages.last[:content]
    assert_equal "Message #{Chat::Conversation::MAX_API_MESSAGES + 4}", last_content
  end

  test "messages_for_api truncates large tool content" do
    conversation = chat_conversations(:pro_conversation)
    large_json = ({ data: "x" * 3000 }).to_json
    conversation.messages.create!(
      role: "tool",
      content: large_json,
      tool_call_id: "call_123",
      tool_name: "search_recipes"
    )

    api_messages = conversation.messages_for_api
    tool_message = api_messages.find { |m| m[:role] == "tool" }
    assert_operator tool_message[:content].size, :<=, Chat::Conversation::MAX_TOOL_CONTENT_SIZE
  end

  test "messages_for_api does not truncate small tool content" do
    conversation = chat_conversations(:pro_conversation)
    small_json = '{"title":"Pasta"}'
    conversation.messages.create!(
      role: "tool",
      content: small_json,
      tool_call_id: "call_456",
      tool_name: "get_recipe_details"
    )

    api_messages = conversation.messages_for_api
    tool_message = api_messages.find { |m| m[:role] == "tool" }
    assert_equal small_json, tool_message[:content]
  end

  test "messages_for_api does not truncate user or assistant content" do
    conversation = chat_conversations(:pro_conversation)
    long_content = "x" * 5000
    conversation.messages.create!(role: "user", content: long_content)

    api_messages = conversation.messages_for_api
    user_message = api_messages.select { |m| m[:role] == "user" }.last
    assert_equal long_content, user_message[:content]
  end

  test "messages_for_api includes multimodal content for image messages" do
    conversation = chat_conversations(:pro_conversation)
    message = conversation.messages.create!(role: "user", content: "Identify this dish")
    message.images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/vaporwave.jpeg")),
      filename: "dish.jpg",
      content_type: "image/jpeg"
    )
    message.reload

    api_message = conversation.messages_for_api.last

    assert_kind_of Array, api_message[:content]
    assert_equal "image_url", api_message[:content].last[:type]
  end
end
