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
require "base64"

class Chat::Message < ApplicationRecord
  self.table_name = "chat_messages"

  ROLES = %w[system user assistant tool].freeze
  MAX_IMAGES = 3
  MAX_IMAGE_SIZE = 8.megabytes

  belongs_to :conversation, class_name: "Chat::Conversation", touch: true
  has_many_attached :images

  validates :role, presence: true, inclusion: { in: ROLES }
  validate :content_or_images_present
  validate :images_are_supported

  scope :visible, -> { where(role: %w[user assistant]) }
  scope :chronological, -> { order(:created_at) }

  serialize :tool_calls, coder: JSON

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end

  def api_content
    return content.to_s unless user? && images.attached?

    parts = []
    parts << { type: "text", text: content.presence || "Please analyze these image(s) and help based on them." }
    parts.concat(images.first(MAX_IMAGES).map { |image| image_part(image) })
    parts
  end

  private

  def content_or_images_present
    return if content.present? || images.attached? || tool_calls.present? || tool_call_id.present?

    errors.add(:base, "Message can't be blank")
  end

  def images_are_supported
    return unless images.attached?

    if images.count > MAX_IMAGES
      errors.add(:images, "can include up to #{MAX_IMAGES} images")
    end

    images.each do |image|
      unless image.content_type.to_s.start_with?("image/")
        errors.add(:images, "must be image files")
      end

      if image.blob.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, "must be smaller than #{MAX_IMAGE_SIZE / 1.megabyte}MB")
      end
    end
  end

  def image_part(image)
    {
      type: "image_url",
      image_url: {
        url: data_url_for(image)
      }
    }
  end

  def data_url_for(image)
    encoded = Base64.strict_encode64(image.download)
    "data:#{image.content_type};base64,#{encoded}"
  end
end
