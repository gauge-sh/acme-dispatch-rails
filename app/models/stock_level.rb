class StockLevel < ApplicationRecord
  belongs_to :part

  validates :quantity_on_hand, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def adjust!(delta, by: nil, note: nil)
    apply(by: by, note: note) { Dispatch::Stock.adjust(quantity_on_hand, delta) }
  end

  def consume!(quantity, note: nil)
    apply(note: note) { Dispatch::Stock.consume(quantity_on_hand, quantity) }
  end

  def release!(quantity, note: nil)
    apply(note: note) { Dispatch::Stock.release(quantity_on_hand, quantity) }
  end

  private

  # The audit row rides in the same transaction as the movement: either both
  # exist or neither does.
  def apply(by: nil, note: nil)
    transaction do
      lock!
      before = quantity_on_hand
      update!(quantity_on_hand: yield)
      StockAdjustment.create!(
        part_id: part_id,
        user: by,
        delta: quantity_on_hand - before,
        quantity_after: quantity_on_hand,
        note: note
      )
    end
    self
  end
end
