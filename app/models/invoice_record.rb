# What a finished job should bill: labor, parts, and the final total, with
# the line items that produced them. A record of amounts only — nothing here
# collects money. Immutable once written.
class InvoiceRecord < ApplicationRecord
  belongs_to :job
  has_many :line_items, -> { order(:position) },
    class_name: "InvoiceLineItem", dependent: :destroy, inverse_of: :invoice_record

  validates :job_id, uniqueness: true
  validates :labor_cents, :parts_cents, :total_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
