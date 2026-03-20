class Family < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  has_many :family_memberships, dependent: :destroy
  has_many :members, through: :family_memberships, source: :user
  has_many :family_cookbooks, dependent: :destroy

  validates :name, presence: true

  def owner
    family_memberships.find_by(role: :owner)&.user
  end

  def member?(user)
    family_memberships.exists?(user: user)
  end

  def admin_or_owner?(user)
    family_memberships.exists?(user: user, role: [:owner, :admin])
  end
end
