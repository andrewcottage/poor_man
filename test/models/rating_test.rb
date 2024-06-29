# == Schema Information
#
# Table name: ratings
#
#  id         :integer          not null, primary key
#  recipe_id  :integer          not null
#  user_id    :integer          not null
#  value      :integer          not null
#  comment    :text(200)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class RatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
