module Dispatch
  module Stock
    module_function

    # Returns the quantity a stock level should hold after `delta` is applied.
    # A rejected adjustment writes nothing because there is nothing to write:
    # the caller persists the returned value or nothing at all.
    def adjust(quantity_on_hand, delta)
      raise ValidationFailed, "delta must not be zero" if delta.zero?

      result = quantity_on_hand + delta
      raise InsufficientStock, "not enough stock on hand" if result.negative?

      result
    end

    def check_quantity!(quantity)
      return if quantity >= 1

      raise ValidationFailed, "quantity must be greater than zero"
    end

    def consume(quantity_on_hand, quantity)
      check_quantity!(quantity)
      adjust(quantity_on_hand, -quantity)
    end

    def release(quantity_on_hand, quantity)
      check_quantity!(quantity)
      adjust(quantity_on_hand, quantity)
    end
  end
end
