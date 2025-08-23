class CreateFamilyMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :family_memberships do |t|
      t.references :family, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.string :invitation_token
      t.datetime :invited_at
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :family_memberships, [:family_id, :user_id], unique: true
    add_index :family_memberships, :invitation_token, unique: true
    add_index :family_memberships, :status
  end
end