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
end
