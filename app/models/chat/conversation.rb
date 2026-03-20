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

  def messages_for_api
    messages.order(:created_at).map do |msg|
      entry = { role: msg.role, content: msg.content }
      entry[:tool_calls] = JSON.parse(msg.tool_calls) if msg.tool_calls.present?
      entry[:tool_call_id] = msg.tool_call_id if msg.tool_call_id.present?
      entry
    end
  end

  def display_title
    title.presence || first_user_message&.content.to_s.truncate(48) || "New chat"
  end

  def preview_text
    messages.visible.chronological.last&.content.to_s.truncate(72)
  end

  def assign_title_from!(content)
    normalized = content.to_s.squish.truncate(60)
    return if normalized.blank?

    update!(title: normalized)
  end

  private

  def first_user_message
    messages.where(role: "user").chronological.first
  end
end
