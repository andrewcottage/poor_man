class FamilyMembership < ApplicationRecord
  belongs_to :family
  belongs_to :user
  
  enum status: { pending: 0, accepted: 1, declined: 2 }
  
  validates :family_id, uniqueness: { scope: :user_id }
  validates :invitation_token, uniqueness: true, allow_nil: true
  
  before_create :generate_invitation_token, if: :pending?
  before_create :set_invited_at, if: :pending?
  
  scope :by_status, ->(status) { where(status: status) }
  
  def accept!
    update!(status: :accepted, accepted_at: Time.current)
  end
  
  def decline!
    update!(status: :declined)
  end
  
  def expired?
    return false unless pending?
    invited_at && invited_at < 30.days.ago
  end
  
  private
  
  def generate_invitation_token
    self.invitation_token = SecureRandom.urlsafe_base64(32)
  end
  
  def set_invited_at
    self.invited_at = Time.current
  end
end