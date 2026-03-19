class Chat::Conversation < ApplicationRecord
  self.table_name = "chat_conversations"

  belongs_to :user
  has_many :messages, class_name: "Chat::Message", foreign_key: :conversation_id, dependent: :destroy

  def messages_for_api
    messages.order(:created_at).map do |msg|
      entry = { role: msg.role, content: msg.content }
      entry[:tool_calls] = JSON.parse(msg.tool_calls) if msg.tool_calls.present?
      entry[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?
      entry
    end
  end
end
