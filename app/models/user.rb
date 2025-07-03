# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  admin           :boolean
#  api_key         :string
#  email           :string           not null
#  name            :string
#  password_digest :string
#  provider        :string
#  recovery_digest :string
#  uid             :string
#  username        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_api_key   (api_key) UNIQUE
#  index_users_on_email     (email) UNIQUE
#  index_users_on_username  (username) UNIQUE
#
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true

  normalizes :email, with: -> email { email.downcase } 

  attribute :admin, :boolean, default: false
  attribute :api_key, default: -> { SecureRandom.hex(15) }
  attribute :notify_new_recipes, :boolean, default: true

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
