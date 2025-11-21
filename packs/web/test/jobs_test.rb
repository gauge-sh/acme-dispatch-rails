require_relative "web_case"

class JobsTest < WebCase
  setup { sign_in_dispatcher }

  def book_furnace(from: 9, to: 11)
    Appointment.create!(
      job: jobs(:furnace), technician: technicians(:reyes),
      scheduled_start: Time.utc(2026, 3, 4, from), scheduled_end: Time.utc(2026, 3, 4, to)
    )
  end

  test "lists jobs with filters" do
    get jobs_path
    assert_select "td a", text: "Furnace not igniting"

    get jobs_path, params: { priority: "urgent" }
    assert_select "td a", text: "Furnace not igniting"
    assert_select "td a", text: "Deck oven runs cold", count: 0

    get jobs_path, params: { q: "oven" }
    assert_select "td a", text: "Deck oven runs cold"

    get jobs_path, params: { status: "invoiced" }
    assert_select ".empty", text: "No jobs match those filters."
  end

  test "opens a job from the form" do
    post jobs_path, params: { job: { customer_id: customers(:quinn).id, title: "Water heater pilot", priority: "urgent" } }
    job = Job.find_by!(title: "Water heater pilot")
    assert_equal "requested", job.status
    assert_redirected_to job_path(job)
  end

  test "renders validation errors on create" do
    post jobs_path, params: { job: { customer_id: customers(:quinn).id, title: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors li"
  end

  test "the detail page offers only legal transitions" do
    get job_path(jobs(:furnace))
    assert_select "form[action=?] button", transition_job_path(jobs(:furnace), status: "scheduled")
    assert_select "form[action=?] button", transition_job_path(jobs(:furnace), status: "cancelled")
    assert_select "form[action*=?]", "status=completed", count: 0
  end

  test "transitions move the job and illegal ones flash" do
    book_furnace
    post transition_job_path(jobs(:furnace), status: "scheduled")
    assert_equal "scheduled", jobs(:furnace).reload.status

    post transition_job_path(jobs(:furnace), status: "completed")
    follow_redirect!
    assert_select ".flash-alert", text: /Cannot move a job/
    assert_equal "scheduled", jobs(:furnace).reload.status
  end

  test "scheduling without an appointment explains itself" do
    post transition_job_path(jobs(:furnace), status: "scheduled")
    follow_redirect!
    assert_select ".flash-alert", text: /needs an appointment/
  end

  test "schedules a visit through the form and surfaces conflicts" do
    post job_appointments_path(jobs(:furnace)), params: { appointment: {
      technician_id: technicians(:reyes).id,
      scheduled_start: "2026-03-04T09:00", scheduled_end: "2026-03-04T11:00"
    } }
    assert_redirected_to job_path(jobs(:furnace))
    assert_equal 1, jobs(:furnace).appointments.count

    post job_appointments_path(jobs(:oven)), params: { appointment: {
      technician_id: technicians(:reyes).id,
      scheduled_start: "2026-03-04T10:00", scheduled_end: "2026-03-04T12:00"
    } }
    assert_response :unprocessable_entity
    assert_select ".errors li", text: /already booked/
    assert_equal 0, jobs(:oven).appointments.count
  end

  test "reschedules an appointment" do
    appointment = book_furnace
    patch appointment_path(appointment), params: { appointment: { scheduled_end: "2026-03-04T12:00" } }
    assert_redirected_to job_path(jobs(:furnace))
    assert_equal Time.utc(2026, 3, 4, 12), appointment.reload.scheduled_end
  end

  test "records and returns parts from the job page" do
    post job_job_parts_path(jobs(:furnace)), params: { part_id: parts(:igniter).id, quantity: 3 }
    assert_redirected_to job_path(jobs(:furnace))
    assert_equal 7, stock_levels(:igniter).reload.quantity_on_hand

    post job_job_parts_path(jobs(:furnace)), params: { part_id: parts(:igniter).id, quantity: 99 }
    follow_redirect!
    assert_select ".flash-alert", text: /Not enough stock/

    job_part = jobs(:furnace).job_parts.sole
    delete job_part_path(job_part)
    assert_equal 10, stock_levels(:igniter).reload.quantity_on_hand
  end

  test "invoices a completed job from the page" do
    book_furnace
    job = jobs(:furnace)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")

    get job_path(job)
    assert_select "form[action=?]", invoice_job_path(job)

    post invoice_job_path(job)
    record = job.reload.invoice_record
    assert_redirected_to invoice_record_path(record)
    assert_equal "invoiced", job.status
  end

  test "an invoiced job cannot be deleted from the ui" do
    book_furnace
    job = jobs(:furnace)
    job.transition_to!("scheduled").transition_to!("in_progress").transition_to!("completed")
    job.invoice!

    delete job_path(job)
    follow_redirect!
    assert_select ".flash-alert", text: /cannot be deleted/
    assert Job.exists?(job.id)
  end
end
