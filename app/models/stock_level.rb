class StockLevel < ApplicationRecord
  belongs_to :part

  validates :quantity_on_hand, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def adjust!(delta)
    apply { Dispatch::Stock.adjust(quantity_on_hand, delta) }
  end

  def consume!(quantity)
    apply { Dispatch::Stock.consume(quantity_on_hand, quantity) }
  end

  def release!(quantity)
    apply { Dispatch::Stock.release(quantity_on_hand, quantity) }
  end

  private

  def apply
    transaction do
      lock!
      update!(quantity_on_hand: yield)
    end
    self
  end
end
