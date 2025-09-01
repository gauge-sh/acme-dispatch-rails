require "test_helper"

class JobTest < ActiveSupport::TestCase
  test "starts as a normal-priority request" do
    job = Job.create!(customer: customers(:quinn), title: "Replace thermostat")
    assert_equal "requested", job.status
    assert_equal "normal", job.priority
  end

  test "title is trimmed and required" do
    job = Job.new(customer: customers(:quinn), title: "  Replace thermostat ")
    job.valid?
    assert_equal "Replace thermostat", job.title

    assert_not Job.new(customer: customers(:quinn), title: "  ").valid?
    assert_not Job.new(customer: customers(:quinn), title: "x" * 161).valid?
  end

  test "description is optional and bounded" do
    job = Job.new(customer: customers(:quinn), title: "Replace thermostat", description: "")
    assert job.valid?
    assert_nil job.description

    job.description = "x" * 4001
    assert_not job.valid?
  end

  test "priority and status only take the wire values" do
    job = jobs(:fence_light)
    job.priority = "asap"
    assert_not job.valid?

    job.priority = "urgent"
    assert job.valid?
  end

  test "a job cannot be scheduled without an appointment" do
    job = jobs(:fence_light)
    error = assert_raises Dispatch::ValidationFailed do
      job.transition_to!("scheduled")
    end
    assert_equal "a job needs an appointment before it can be scheduled", error.message

    job.appointments.create!(
      technician: technicians(:okada),
      scheduled_start: Time.utc(2025, 9, 12, 9),
      scheduled_end: Time.utc(2025, 9, 12, 10)
    )
    job.transition_to!("scheduled")
    assert_equal "scheduled", job.reload.status
  end

  test "legal transitions move the status" do
    job = jobs(:fence_light)
    job.transition_to!("cancelled")
    assert_equal "cancelled", job.reload.status
  end

  test "illegal transitions raise and change nothing" do
    job = jobs(:fence_light)
    error = assert_raises Dispatch::InvalidTransition do
      job.transition_to!("completed")
    end
    assert_equal "cannot move a job from requested to completed", error.message
    assert_equal "requested", job.reload.status
  end

  test "unknown statuses are refused before the machine is consulted" do
    error = assert_raises Dispatch::ValidationFailed do
      jobs(:fence_light).transition_to!("done")
    end
    assert_equal "unknown status", error.message
  end
end
