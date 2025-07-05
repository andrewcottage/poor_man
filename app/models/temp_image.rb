# == Schema Information
#
# Table name: temp_images
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ref_id     :string
#
class TempImage < ApplicationRecord
    has_one_attached :image

    belongs_to :recipe, optional: true, foreign_key: :ref_id, primary_key: :ref_id
end
