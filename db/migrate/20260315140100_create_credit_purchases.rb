class CreateCreditPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :pack_id, null: false
      t.integer :credits, null: false
      t.integer :status, null: false, default: 0
      t.datetime :credited_at
      t.string :stripe_checkout_session_id
      t.string :stripe_customer_id
      t.string :stripe_payment_intent_id
      t.string :stripe_price_id
      t.text :payload

      t.timestamps
    end

    add_index :credit_purchases, :pack_id
    add_index :credit_purchases, :stripe_checkout_session_id, unique: true
    add_index :credit_purchases, :stripe_payment_intent_id
  end
end
