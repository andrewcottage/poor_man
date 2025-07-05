class CreateTempImages < ActiveRecord::Migration[8.1]
  def change
    create_table :temp_images do |t|
      t.string :ref_id

      t.timestamps
    end
  end
end
