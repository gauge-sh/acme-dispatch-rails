require "test_helper"

class InvoiceRecordTest < ActiveSupport::TestCase
  def complete_furnace_job
    job = jobs(:furnace)
    Appointment.create!(
      job: job,
      technician: technicians(:reyes),
      scheduled_start: Time.utc(2025, 3, 12, 13),
      scheduled_end: Time.utc(2025, 3, 12, 14, 30)
    )
    JobPart.create!(job: job, part: parts(:igniter), quantity: 3)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")
    job
  end

  test "invoicing a completed job writes the record and moves the status" do
    job = complete_furnace_job
    record = job.invoice!

    assert_equal "invoiced", job.reload.status
    assert_equal 19200, record.labor_cents
    assert_equal 3897, record.parts_cents
    # The furnace job is urgent: 23097 * 1.1 rounds half away from zero.
    assert_equal 25407, record.total_cents

    labor, part = record.line_items.to_a
    assert_equal "Dana Reyes — 1.5h on 2025-03-12", labor.description
    assert_equal 1.5, labor.quantity
    assert_equal 8000, labor.unit_cents
    assert_equal 19200, labor.amount_cents
    assert_not labor.weekend

    assert_equal "IGN-4420 — Hot surface igniter", part.description
    assert_equal 3, part.quantity
    assert_equal 1299, part.unit_cents
    assert_equal 3897, part.amount_cents
  end

  test "labor lines order by start then id, parts by job part id" do
    job = jobs(:oven)
    first = Appointment.create!(job: job, technician: technicians(:okada),
      scheduled_start: Time.utc(2025, 3, 12, 13), scheduled_end: Time.utc(2025, 3, 12, 14))
    earlier = Appointment.create!(job: job, technician: technicians(:reyes),
      scheduled_start: Time.utc(2025, 3, 12, 9), scheduled_end: Time.utc(2025, 3, 12, 10))
    JobPart.create!(job: job, part: parts(:filter), quantity: 1)
    JobPart.create!(job: job, part: parts(:igniter), quantity: 1)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")

    record = job.invoice!
    descriptions = record.line_items.map(&:description)

    assert_equal 4, descriptions.size
    assert_includes descriptions[0], "Dana Reyes"
    assert_includes descriptions[1], "Ben Okada"
    assert_includes descriptions[2], "FLT-2001"
    assert_includes descriptions[3], "IGN-4420"
    assert_equal [ earlier.hours, first.hours, 1, 1 ], record.line_items.map(&:quantity)
  end

  test "only a completed job can be invoiced" do
    error = assert_raises Dispatch::InvalidTransition do
      jobs(:oven).invoice!
    end
    assert_equal "only a completed job can be invoiced", error.message
    assert_nil jobs(:oven).reload.invoice_record
  end

  test "a second invoice is refused as a duplicate" do
    job = complete_furnace_job
    job.invoice!

    error = assert_raises Dispatch::ValidationFailed do
      job.invoice!
    end
    assert_equal "job is already invoiced", error.message
    assert_equal 1, InvoiceRecord.where(job: job).count
  end

  test "the transition endpoint can never reach invoiced" do
    job = complete_furnace_job
    assert_raises Dispatch::InvalidTransition do
      job.transition_to!("invoiced")
    end
    assert_equal "completed", job.reload.status
  end
end
