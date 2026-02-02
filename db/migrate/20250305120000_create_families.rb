class CreateFamilies < ActiveRecord::Migration[8.0]
  def change
    create_table :families do |t|
      t.string :name, null: false
      t.text :description
      t.integer :creator_id, null: false
      t.string :slug
      t.timestamps
    end

    add_index :families, :creator_id
    add_index :families, :slug, unique: true
    add_foreign_key :families, :users, column: :creator_id
  end
end