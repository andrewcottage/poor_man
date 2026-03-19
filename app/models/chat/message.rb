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
