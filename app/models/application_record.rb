class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :latest, -> { order(created_at: :desc) }
  scope :descending, -> { order(created_at: :desc) }
  scope :ascending, -> { order(created_at: :asc) }
end
