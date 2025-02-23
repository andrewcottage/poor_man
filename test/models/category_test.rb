# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  description    :text
#  recipies_count :integer
#  slug           :string
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_categories_on_slug  (slug) UNIQUE
#
require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
