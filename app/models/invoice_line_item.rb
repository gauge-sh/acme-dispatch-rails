class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice_record

  enum :kind, { labor: "labor", part: "part" }

  validates :position, :description, :quantity, :unit_cents, :amount_cents, presence: true
end
