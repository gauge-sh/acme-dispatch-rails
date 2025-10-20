class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  has_many :api_tokens, dependent: :destroy

  enum :role, { admin: "admin", dispatcher: "dispatcher" }, default: "dispatcher", validate: true

  normalizes :name, with: ->(value) { value.strip }

  validates :name, presence: true, length: { maximum: 120 }

  scope :active, -> { where(is_active: true) }

  validate :keep_one_active_admin, on: :update
  before_destroy :refuse_removing_last_active_admin

  # Devise consults this on every sign-in and every warden fetch, so
  # deactivating a user also ends their existing sessions.
  def active_for_authentication?
    super && is_active
  end

  def inactive_message = :invalid

  private

  def other_active_admin_exists?
    User.active.where(role: "admin").where.not(id: id).exists?
  end

  # Demoting or deactivating the last active admin would lock everyone out
  # of user management; so would deleting them.
  def keep_one_active_admin
    return unless role_in_database == "admin" && is_active_in_database
    return if admin? && is_active
    return if other_active_admin_exists?

    errors.add(:base, "cannot remove the last active admin")
  end

  def refuse_removing_last_active_admin
    return unless admin? && is_active
    return if other_active_admin_exists?

    raise Dispatch::ValidationFailed, "cannot remove the last active admin"
  end
end
