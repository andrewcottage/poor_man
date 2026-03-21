class DropChatTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :chat_messages, if_exists: true
    drop_table :chat_conversations, if_exists: true
  end

  def down
    create_table :chat_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.timestamps
    end

    create_table :chat_messages do |t|
      t.references :chat_conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content
      t.json :tool_calls
      t.string :tool_call_id
      t.timestamps
    end
  end
end
