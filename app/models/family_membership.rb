class FamilyMembership < ApplicationRecord
  belongs_to :family
  belongs_to :user

  enum :role, { member: 0, admin: 1, owner: 2 }

  validates :user_id, uniqueness: { scope: :family_id, message: "is already a member of this family" }
  validates :role, presence: true

  validate :one_owner_per_family, on: :create

  private

  def one_owner_per_family
    if owner? && family&.family_memberships&.owner&.exists?
      errors.add(:role, "family already has an owner")
    end
  end
end
