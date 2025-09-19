require "test_helper"

class JobPartTest < ActiveSupport::TestCase
  test "recording a part takes it out of stock" do
    JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 3)
    assert_equal 7, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "insufficient stock rejects the record and writes nothing" do
    assert_raises Dispatch::InsufficientStock do
      JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 11)
    end
    assert_equal 10, stock_levels(:igniter).reload.quantity_on_hand
    assert_equal 0, jobs(:furnace).job_parts.count
  end

  test "quantity must be positive" do
    error = assert_raises Dispatch::ValidationFailed do
      JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 0)
    end
    assert_equal "quantity must be greater than zero", error.message
  end

  test "the same part twice makes two rows" do
    2.times { JobPart.create!(job: jobs(:furnace), part: parts(:filter), quantity: 1) }
    assert_equal 2, jobs(:furnace).job_parts.where(part: parts(:filter)).count
    assert_equal 22, stock_levels(:filter).reload.quantity_on_hand
  end

  test "terminal jobs take no parts" do
    %w[invoiced cancelled].each do |status|
      jobs(:oven).update_column(:status, status)
      error = assert_raises Dispatch::ValidationFailed do
        JobPart.create!(job: jobs(:oven), part: parts(:filter), quantity: 1)
      end
      assert_equal "parts cannot be added to a job that is #{status}", error.message
    end
  end

  test "a completed job still takes parts" do
    jobs(:oven).update_column(:status, "completed")
    assert JobPart.create!(job: jobs(:oven), part: parts(:filter), quantity: 2).persisted?
  end

  test "deleting a record returns the quantity to stock" do
    record = JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 3)
    record.destroy!
    assert_equal 10, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "an invoiced job's parts are frozen" do
    record = JobPart.create!(job: jobs(:furnace), part: parts(:igniter), quantity: 3)
    jobs(:furnace).update_column(:status, "invoiced")

    error = assert_raises Dispatch::ValidationFailed do
      record.destroy
    end
    assert_equal "an invoiced job cannot be changed", error.message
    assert JobPart.exists?(record.id)
    assert_equal 7, stock_levels(:igniter).reload.quantity_on_hand
  end
end
