class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: -> email { email.downcase } 

  attribute :admin, :boolean, default: true

  def self.default_author
    User.where(admin: true).first
  end
end
