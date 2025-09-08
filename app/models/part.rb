class Part < ApplicationRecord
  SKU_FORMAT = /\A[A-Z0-9-]+\z/

  has_one :stock_level, dependent: :destroy

  normalizes :sku, :name, with: ->(value) { value.strip }

  validates :sku, presence: true, length: { maximum: 40 }, uniqueness: true,
    format: { with: SKU_FORMAT, message: "must be upper-case letters, digits and dashes" }
  validates :name, presence: true, length: { maximum: 160 }
  validates :unit_cost_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :price_covers_cost

  # Every part tracks stock from the moment it exists.
  after_create { create_stock_level!(quantity_on_hand: 0) }

  private

  def price_covers_cost
    return if unit_price_cents.blank? || unit_cost_cents.blank?
    return if unit_price_cents >= unit_cost_cents

    errors.add(:unit_price_cents, "unit price cannot be below unit cost")
  end
end
