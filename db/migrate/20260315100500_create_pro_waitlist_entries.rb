class CreateProWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :pro_waitlist_entries do |t|
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :source
      t.string :plan_preference

      t.timestamps
    end

    add_index :pro_waitlist_entries, :email, unique: true
  end
end
