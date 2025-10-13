class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  has_many :api_tokens, dependent: :destroy

  enum :role, { admin: "admin", dispatcher: "dispatcher" }, default: "dispatcher", validate: true

  normalizes :name, with: ->(value) { value.strip }

  validates :name, presence: true, length: { maximum: 120 }

  scope :active, -> { where(is_active: true) }

  # Devise consults this on every sign-in and every warden fetch, so
  # deactivating a user also ends their existing sessions.
  def active_for_authentication?
    super && is_active
  end

  def inactive_message = :invalid
end
