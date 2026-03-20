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
class Chat::Message < ApplicationRecord
  self.table_name = "chat_messages"

  ROLES = %w[system user assistant tool].freeze

  belongs_to :conversation, class_name: "Chat::Conversation"

  validates :role, presence: true, inclusion: { in: ROLES }

  scope :visible, -> { where(role: %w[user assistant]) }
  scope :chronological, -> { order(:created_at) }

  serialize :tool_calls, coder: JSON

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end
end
