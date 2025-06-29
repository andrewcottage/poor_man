class CreateCookbooks < ActiveRecord::Migration[8.0]
  def change
    create_table :cookbooks do |t|
      t.string :name, null: false
      t.text :description
      t.references :family, null: false, foreign_key: true
      t.boolean :is_default, default: false, null: false
      t.string :slug
      t.timestamps
    end

    add_index :cookbooks, [:family_id, :slug], unique: true
    add_index :cookbooks, [:family_id, :is_default]
  end
end