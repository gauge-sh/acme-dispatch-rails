require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  def book(job: jobs(:furnace), technician: technicians(:reyes), from:, to:)
    Appointment.create!(
      job: job,
      technician: technician,
      scheduled_start: Time.utc(2025, 9, 10, *from),
      scheduled_end: Time.utc(2025, 9, 10, *to)
    )
  end

  test "books a free technician" do
    appointment = book(from: [ 9 ], to: [ 11 ])
    assert appointment.persisted?
    assert_equal 2r, appointment.hours
  end

  test "must end after it starts" do
    error = assert_raises Dispatch::ValidationFailed do
      book(from: [ 11 ], to: [ 11 ])
    end
    assert_equal "appointment must end after it starts", error.message
  end

  test "rejects a double booking" do
    book(from: [ 9 ], to: [ 11 ])
    error = assert_raises Dispatch::ScheduleConflict do
      book(job: jobs(:oven), from: [ 10 ], to: [ 12 ])
    end
    assert_equal "technician is already booked for that time", error.message
  end

  test "back-to-back appointments are fine" do
    book(from: [ 9 ], to: [ 11 ])
    assert book(job: jobs(:oven), from: [ 11 ], to: [ 13 ]).persisted?
  end

  test "the same window is free for another technician" do
    book(from: [ 9 ], to: [ 11 ])
    assert book(technician: technicians(:okada), from: [ 9 ], to: [ 11 ]).persisted?
  end

  test "rescheduling does not conflict with itself" do
    appointment = book(from: [ 9 ], to: [ 11 ])
    appointment.update!(scheduled_start: Time.utc(2025, 9, 10, 9, 30), scheduled_end: Time.utc(2025, 9, 10, 11, 30))
    assert_equal Time.utc(2025, 9, 10, 9, 30), appointment.reload.scheduled_start
  end

  test "rescheduling still respects other bookings" do
    book(from: [ 9 ], to: [ 11 ])
    second = book(job: jobs(:oven), from: [ 11 ], to: [ 12 ])

    assert_raises Dispatch::ScheduleConflict do
      second.update!(scheduled_start: Time.utc(2025, 9, 10, 10, 30))
    end
  end

  test "completion notes are optional and bounded" do
    appointment = book(from: [ 9 ], to: [ 11 ])
    appointment.update!(completion_notes: "  Replaced igniter  ")
    assert_equal "Replaced igniter", appointment.completion_notes

    appointment.completion_notes = "x" * 2001
    assert_not appointment.valid?

    appointment.completion_notes = ""
    appointment.valid?
    assert_nil appointment.completion_notes
  end
end
