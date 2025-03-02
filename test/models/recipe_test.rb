# == Schema Information
#
# Table name: recipes
#
#  id            :integer          not null, primary key
#  blurb         :text
#  cost_cents    :integer          default(0), not null
#  cost_currency :string           default("USD"), not null
#  difficulty    :integer          default(0)
#  prep_time     :integer          default(0)
#  slug          :string
#  tag_names     :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :integer
#  category_id   :integer          not null
#
# Indexes
#
#  index_recipes_on_author_id    (author_id)
#  index_recipes_on_category_id  (category_id)
#  index_recipes_on_slug         (slug) UNIQUE
#
# Foreign Keys
#
#  author_id    (author_id => users.id)
#  category_id  (category_id => categories.id)
#
require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
