class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan, null: false
      t.string :status, null: false, default: "pending"
      t.string :stripe_checkout_session_id
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_price_id
      t.datetime :current_period_end
      t.datetime :canceled_at
      t.text :payload

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :plan
    add_index :subscriptions, :stripe_checkout_session_id, unique: true
    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :stripe_subscription_id
  end
end
