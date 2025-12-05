require "test_helper"

class StockAdjustmentTest < ActiveSupport::TestCase
  test "manual adjustments record who and how much" do
    stock_levels(:igniter).adjust!(5, by: users(:teddy), note: "manual adjustment")

    adjustment = parts(:igniter).stock_adjustments.sole
    assert_equal 5, adjustment.delta
    assert_equal 15, adjustment.quantity_after
    assert_equal users(:teddy), adjustment.user
    assert_equal "manual adjustment", adjustment.note
  end

  test "job usage writes system rows on both consume and release" do
    record = JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 3)
    record.destroy!

    notes = parts(:igniter).stock_adjustments.order(:id).map(&:note)
    assert_equal [ "used on job ##{jobs(:furnace).id}", "returned from job ##{jobs(:furnace).id}" ], notes
    assert_equal [ -3, 3 ], parts(:igniter).stock_adjustments.order(:id).map(&:delta)
    assert parts(:igniter).stock_adjustments.all? { |a| a.user.nil? }
  end

  test "a rejected movement writes no audit row" do
    assert_raises Dispatch::InsufficientStock do
      stock_levels(:igniter).adjust!(-11)
    end
    assert_equal 0, parts(:igniter).stock_adjustments.count
  end
end
