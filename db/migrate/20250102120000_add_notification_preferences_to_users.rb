class AddNotificationPreferencesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notify_new_recipes, :boolean, default: true
  end
end