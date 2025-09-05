require "test_helper"

module Dispatch
  class StockTest < ActiveSupport::TestCase
    test "adjust moves the quantity by the delta" do
      assert_equal 12, Stock.adjust(10, 2)
      assert_equal 8, Stock.adjust(10, -2)
      assert_equal 0, Stock.adjust(10, -10)
    end

    test "a zero delta is refused" do
      error = assert_raises(ValidationFailed) { Stock.adjust(10, 0) }
      assert_equal "delta must not be zero", error.message
    end

    test "stock cannot go negative" do
      error = assert_raises(InsufficientStock) { Stock.adjust(10, -11) }
      assert_equal "not enough stock on hand", error.message
      assert_raises(InsufficientStock) { Stock.adjust(0, -1) }
    end

    test "consume takes a positive quantity out" do
      assert_equal 7, Stock.consume(10, 3)
      assert_equal 0, Stock.consume(3, 3)
      assert_raises(InsufficientStock) { Stock.consume(2, 3) }
    end

    test "release puts a positive quantity back" do
      assert_equal 13, Stock.release(10, 3)
    end

    test "consume and release refuse non-positive quantities" do
      [ 0, -1 ].each do |quantity|
        error = assert_raises(ValidationFailed) { Stock.consume(10, quantity) }
        assert_equal "quantity must be greater than zero", error.message
        assert_raises(ValidationFailed) { Stock.release(10, quantity) }
      end
    end
  end
end
