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

  attribute :admin, :boolean, default: true

  has_many :recipes, foreign_key: 'author_id'

  has_one_attached :avatar

  def self.default_author
    User.where(admin: true).first
  end
end
