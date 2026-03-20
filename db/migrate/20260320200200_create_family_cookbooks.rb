class CreateFamilyCookbooks < ActiveRecord::Migration[8.1]
  def change
    create_table :family_cookbooks do |t|
      t.references :family, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :family_cookbooks, [:family_id, :name], unique: true
  end
end
