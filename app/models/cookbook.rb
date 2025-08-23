class Cookbook < ApplicationRecord
  belongs_to :family
  has_many :recipes, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :family_id }
  validates :description, length: { maximum: 500 }
  
  before_validation :generate_slug
  
  scope :default_cookbooks, -> { where(is_default: true) }
  scope :custom_cookbooks, -> { where(is_default: false) }
  
  def accessible_by?(user)
    family.member?(user)
  end
  
  def editable_by?(user)
    family.member?(user)
  end
  
  def can_manage?(user)
    family.can_manage?(user)
  end
  
  private
  
  def generate_slug
    return if slug.present?
    self.slug = name.parameterize if name.present?
  end
end