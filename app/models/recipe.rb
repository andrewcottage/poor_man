class Recipe < ApplicationRecord
  has_one_attached :image
  has_rich_text :content
end
