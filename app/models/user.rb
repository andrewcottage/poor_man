class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: -> email { email.downcase } 

  attribute :admin, :boolean, default: true

  has_many :recipes, foreign_key: 'author_id'

  has_one_attached :avatar

  def self.default_author
    User.where(admin: true).first
  end
end
