class Customer < ApplicationRecord
  normalizes :name, :service_address, with: ->(value) { value.strip }
  normalizes :contact_email, :phone, with: ->(value) { value.strip.presence }

  validates :name, presence: true, length: { maximum: 160 }
  validates :service_address, presence: true, length: { maximum: 240 }
  validates :contact_email, format: { with: /@/, message: "must contain @" }, allow_nil: true
  validates :phone, length: { in: 7..32 }, allow_nil: true
end
