# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  username        :string
#  password_digest :string
#  recovery_digest :string
#  admin           :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true

  normalizes :email, with: -> email { email.downcase } 

  attribute :admin, :boolean, default: false
  attribute :api_key, default: -> { SecureRandom.hex(15) }

  has_many :recipes, foreign_key: 'author_id'
  has_many :ratings
  has_many :favorites
  has_many :favorite_recipes, through: :favorites, source: :recipe

  has_one_attached :avatar

  def self.default_author
    User.where(admin: true).first
  end

  def self.from_omniauth(auth)   
    User.find_or_create_by(uid: auth['uid'], provider: auth['provider']) do |u|
      auth_email = auth.dig("info", "email")
      u.email = auth_email
      u.username = auth_email.split('@').first
      u.password = SecureRandom.hex(15)     
    end
  end
end
