class CreateChatConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.timestamps
    end

    create_table :chat_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :chat_conversations }
      t.string :role, null: false
      t.text :content
      t.text :tool_calls
      t.string :tool_call_id
      t.string :tool_name
      t.timestamps
    end
  end
end
