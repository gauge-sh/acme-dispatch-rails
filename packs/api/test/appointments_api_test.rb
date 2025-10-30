require_relative "api_case"

class AppointmentsApiTest < ApiCase
  def create_appointment(job: jobs(:furnace), technician: technicians(:reyes), start_at: "2025-03-12T09:00:00Z", end_at: "2025-03-12T11:00:00Z", **extra)
    post_api "/appointments", {
      job_id: job.id,
      technician_id: technician.id,
      scheduled_start: start_at,
      scheduled_end: end_at,
      **extra
    }
  end

  test "creates an appointment" do
    create_appointment(completion_notes: "bring a ladder")
    assert_response :created
    assert_equal "2025-03-12T09:00:00Z", body["scheduled_start"]
    assert_equal "bring a ladder", body["completion_notes"]
  end

  test "an overlap for the same technician is a 409" do
    create_appointment
    create_appointment(job: jobs(:oven), start_at: "2025-03-12T10:00:00Z", end_at: "2025-03-12T12:00:00Z")
    assert_response :conflict
    assert_api_error "schedule_conflict", "technician is already booked for that time"
  end

  test "touching windows and other technicians are fine" do
    create_appointment
    create_appointment(job: jobs(:oven), start_at: "2025-03-12T11:00:00Z", end_at: "2025-03-12T12:00:00Z")
    assert_response :created

    create_appointment(technician: technicians(:okada))
    assert_response :created
  end

  test "an inverted window is a validation failure" do
    create_appointment(end_at: "2025-03-12T08:00:00Z")
    assert_response :bad_request
    assert_api_error "validation_failed", "appointment must end after it starts"
  end

  test "a non-iso timestamp is refused" do
    create_appointment(start_at: "yesterday")
    assert_response :bad_request
    assert_equal "validation_failed", body.dig("error", "code")
  end

  test "closed jobs take no appointments over the wire" do
    jobs(:furnace).update_column(:status, "completed")
    create_appointment
    assert_response :bad_request
    assert_api_error "validation_failed", "appointments cannot be added to a job that is completed"
  end

  test "rescheduling skips the appointment itself but not others" do
    first = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 11 ])
    schedule(job: jobs(:oven), technician: technicians(:reyes), from: [ 11 ], to: [ 12 ])

    patch_api "/appointments/#{first.id}", { scheduled_end: "2025-03-12T10:30:00Z" }
    assert_response :success
    assert_equal "2025-03-12T10:30:00Z", body["scheduled_end"]

    patch_api "/appointments/#{first.id}", { scheduled_end: "2025-03-12T11:30:00Z" }
    assert_response :conflict
    assert_api_error "schedule_conflict"
  end

  test "lists order by start then id and filter by window" do
    late = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 14 ], to: [ 15 ])
    early = schedule(job: jobs(:oven), technician: technicians(:okada), from: [ 8 ], to: [ 9 ])

    get_api "/appointments"
    assert_equal [ early.id, late.id ], body["items"].map { |a| a["id"] }

    get_api "/appointments", technician_id: technicians(:reyes).id
    assert_equal [ late.id ], body["items"].map { |a| a["id"] }

    get_api "/appointments", from: "2025-03-12T10:00:00Z"
    assert_equal [ late.id ], body["items"].map { |a| a["id"] }

    get_api "/appointments", to: "2025-03-12T10:00:00Z"
    assert_equal [ early.id ], body["items"].map { |a| a["id"] }

    get_api "/appointments", from: "not-a-time"
    assert_response :bad_request
  end

  test "deletes an appointment" do
    appointment = schedule(job: jobs(:furnace), technician: technicians(:reyes), from: [ 9 ], to: [ 10 ])
    delete_api "/appointments/#{appointment.id}"
    assert_response :no_content
    assert_not Appointment.exists?(appointment.id)
  end
end
