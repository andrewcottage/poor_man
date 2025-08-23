class Family < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  
  has_many :family_memberships, dependent: :destroy
  has_many :members, through: :family_memberships, source: :user
  has_many :active_memberships, -> { where(status: :accepted) }, class_name: 'FamilyMembership'
  has_many :active_members, through: :active_memberships, source: :user
  has_many :pending_memberships, -> { where(status: :pending) }, class_name: 'FamilyMembership'
  has_many :pending_members, through: :pending_memberships, source: :user
  
  has_many :cookbooks, dependent: :destroy
  has_one :default_cookbook, -> { where(is_default: true) }, class_name: 'Cookbook'
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 }
  
  before_validation :generate_slug
  after_create :create_default_cookbook
  after_create :add_creator_as_member
  
  def member?(user)
    return false unless user
    active_members.include?(user) || creator == user
  end
  
  def pending_invitation_for?(user)
    return false unless user
    pending_memberships.exists?(user: user)
  end
  
  def can_manage?(user)
    creator == user
  end
  
  private
  
  def generate_slug
    return if slug.present?
    self.slug = name.parameterize if name.present?
  end
  
  def create_default_cookbook
    cookbooks.create!(
      name: "Family Recipes",
      description: "Default cookbook for #{name}",
      is_default: true,
      slug: "family-recipes"
    )
  end
  
  def add_creator_as_member
    family_memberships.create!(
      user: creator,
      status: :accepted,
      accepted_at: Time.current
    )
  end
end