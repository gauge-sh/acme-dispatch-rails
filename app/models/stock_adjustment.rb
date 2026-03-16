# One row per stock movement, written inside the movement's transaction.
# `user` is present when a person did it directly and null when the movement
# came from job-part bookkeeping.
class StockAdjustment < ApplicationRecord
  belongs_to :part
  belongs_to :user, optional: true

  validates :delta, :quantity_after, presence: true
  validates :note, length: { maximum: 200 }, allow_nil: true
end
