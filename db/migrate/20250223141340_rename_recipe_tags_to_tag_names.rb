class RenameRecipeTagsToTagNames < ActiveRecord::Migration[8.1]
  def change
    rename_column :recipes, :tags, :tag_names
  end
end
