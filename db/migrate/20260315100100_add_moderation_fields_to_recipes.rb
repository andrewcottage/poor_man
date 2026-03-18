class AddModerationFieldsToRecipes < ActiveRecord::Migration[8.1]
  def up
    add_column :recipes, :moderation_status, :integer, default: 0, null: false
    add_column :recipes, :reviewed_at, :datetime
    add_column :recipes, :rejection_reason, :text
    add_reference :recipes, :reviewed_by, foreign_key: { to_table: :users }

    execute <<~SQL.squish
      UPDATE recipes
      SET moderation_status = 1
      WHERE moderation_status = 0
    SQL

    add_index :recipes, :moderation_status
  end

  def down
    remove_index :recipes, :moderation_status
    remove_reference :recipes, :reviewed_by, foreign_key: { to_table: :users }
    remove_column :recipes, :rejection_reason
    remove_column :recipes, :reviewed_at
    remove_column :recipes, :moderation_status
  end
end
