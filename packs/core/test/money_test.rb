require "test_helper"

module Dispatch
  class MoneyTest < ActiveSupport::TestCase
    test "whole cents pass through" do
      assert_equal 16000, Money.round_cents(16000)
      assert_equal 0, Money.round_cents(0)
    end

    test "fractions round to the nearest cent" do
      assert_equal 2666, Money.round_cents(2666.4r)
      assert_equal 25407, Money.round_cents(25406.7r)
      assert_equal 19200, Money.round_cents(1.5r * 8000 * 1.6r)
    end

    test "halves round away from zero, not to even" do
      assert_equal 2667, Money.round_cents(2666.5r)
      assert_equal 2668, Money.round_cents(2667.5r)
      assert_equal 1, Money.round_cents(0.5r)
      assert_equal(-1, Money.round_cents(-0.5r))
      assert_equal(-2668, Money.round_cents(-2667.5r))
    end

    test "repeating decimals stay exact until the rounding" do
      assert_equal 3333, Money.round_cents(1r / 3 * 10000)
      assert_equal 6667, Money.round_cents(2r / 3 * 10000)
    end
  end
end
