require "digest"
require "securerandom"

# A bearer credential for the JSON API. Only the SHA-256 digest is stored;
# the plaintext exists for the single response that announces it.
class ApiToken < ApplicationRecord
  belongs_to :user

  normalizes :name, with: ->(value) { value.strip }
  validates :name, presence: true, length: { maximum: 80 }

  before_create :assign_token

  attr_reader :plaintext

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.authenticate(token)
    return nil if token.blank?

    api_token = find_by(token_hash: digest(token))
    api_token if api_token&.user&.is_active
  end

  # Bookkeeping, not an edit: skips validations and leaves updated_at alone.
  def touch_last_used
    update_column(:last_used_at, Time.current)
  end

  private

  def assign_token
    @plaintext = SecureRandom.hex(20)
    self.token_hash = self.class.digest(@plaintext)
  end
end
