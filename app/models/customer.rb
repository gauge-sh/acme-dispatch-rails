class Customer < ApplicationRecord
  has_many :jobs, dependent: nil

  normalizes :name, :service_address, with: ->(value) { value.strip }
  normalizes :contact_email, :phone, with: ->(value) { value.strip.presence }

  validates :name, presence: true, length: { maximum: 160 }
  validates :service_address, presence: true, length: { maximum: 240 }
  validates :contact_email, format: { with: /@/, message: "must contain @" }, allow_nil: true
  validates :phone, length: { in: 7..32 }, allow_nil: true

  before_destroy :refuse_destroy_with_jobs

  private

  def refuse_destroy_with_jobs
    return unless jobs.exists?

    raise Dispatch::ValidationFailed, "customer has jobs and cannot be deleted"
  end
end
