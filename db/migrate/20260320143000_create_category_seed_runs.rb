class CreateCategorySeedRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :category_seed_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :published_category, foreign_key: { to_table: :categories }
      t.text :prompt, null: false
      t.text :data
      t.text :seed_publish_error
      t.datetime :published_at

      t.timestamps
    end
  end
end
