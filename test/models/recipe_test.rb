# == Schema Information
#
# Table name: recipes
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  title       :string
#  slug        :string
#  tags        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
