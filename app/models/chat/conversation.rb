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
class Chat::Conversation < ApplicationRecord
  self.table_name = "chat_conversations"

  belongs_to :user
  has_many :messages, class_name: "Chat::Message", foreign_key: :conversation_id, dependent: :destroy

  scope :recent_first, -> { order(updated_at: :desc, id: :desc) }

  MAX_API_MESSAGES = 40
  MAX_TOOL_CONTENT_SIZE = 2000

  def messages_for_api
    recent = messages.order(:created_at).last(MAX_API_MESSAGES)
    recent.map do |msg|
      content = msg.role == "tool" ? truncate_tool_content(msg.api_content) : msg.api_content
      entry = { role: msg.role, content: content }
      entry[:tool_calls] = JSON.parse(msg.tool_calls) if msg.tool_calls.present?
      entry[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?
      entry
    end
  end

  def display_title
    return title if title.present?

    first_message = first_user_message
    return "Photo recipe chat" if first_message&.content.blank? && first_message&.images&.attached?

    first_message&.content.to_s.truncate(48).presence || "New chat"
  end

  def preview_text
    latest_message = messages.visible.chronological.last
    return "Shared #{latest_message.images.count} photo#{'s' if latest_message.images.count != 1}" if latest_message&.user? && latest_message.content.blank? && latest_message.images.attached?

    latest_message&.content.to_s.truncate(72)
  end

  def assign_title_from!(content)
    normalized = content.to_s.squish.truncate(60)
    return if normalized.blank?

    update!(title: normalized)
  end

  private

  def truncate_tool_content(content)
    return content unless content.is_a?(String) && content.size > MAX_TOOL_CONTENT_SIZE

    content.truncate(MAX_TOOL_CONTENT_SIZE)
  end

  def first_user_message
    messages.where(role: "user").chronological.first
  end
end
