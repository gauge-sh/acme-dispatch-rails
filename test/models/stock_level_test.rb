require "test_helper"

class StockLevelTest < ActiveSupport::TestCase
  test "adjusting moves the quantity" do
    stock = stock_levels(:igniter)
    stock.adjust!(5)
    assert_equal 15, stock.reload.quantity_on_hand

    stock.adjust!(-15)
    assert_equal 0, stock.reload.quantity_on_hand
  end

  test "an adjustment below zero writes nothing" do
    stock = stock_levels(:igniter)
    assert_raises Dispatch::InsufficientStock do
      stock.adjust!(-11)
    end
    assert_equal 10, stock.reload.quantity_on_hand
  end

  test "a zero delta is refused" do
    assert_raises Dispatch::ValidationFailed do
      stock_levels(:igniter).adjust!(0)
    end
  end

  test "consume and release are bounded the same way" do
    stock = stock_levels(:filter)
    stock.consume!(4)
    assert_equal 20, stock.reload.quantity_on_hand

    stock.release!(2)
    assert_equal 22, stock.reload.quantity_on_hand

    assert_raises Dispatch::InsufficientStock do
      stock_levels(:valve).consume!(1)
    end
  end
end
