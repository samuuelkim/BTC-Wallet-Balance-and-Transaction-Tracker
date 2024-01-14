require 'bcrypt'

class User
  include Mongoid::Document

  field :username, type: String
  field :password_digest, type: String

  has_many :addresses

  validates :username, uniqueness: { message: 'is already taken' }
  validates :password, length: { minimum: 6, message: 'must be at least 6 characters' }

  def password
    @password ||= BCrypt::Password.new(password_digest)
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_digest = @password
  end
end
