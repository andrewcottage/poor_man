class AddFreemiumFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :plan, :string, default: "free", null: false
    add_column :users, :generations_count, :integer, default: 0, null: false
    add_column :users, :generations_reset_at, :datetime
    add_column :users, :plan_expires_at, :datetime
    add_column :users, :free_generation_used_at, :datetime
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string

    add_index :users, :plan
    add_index :users, :stripe_customer_id
    add_index :users, :stripe_subscription_id
  end
end
