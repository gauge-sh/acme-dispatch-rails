require "test_helper"

module Dispatch
  class SchedulingTest < ActiveSupport::TestCase
    def booking(technician_id: 1, starts_at:, ends_at:, id: nil)
      Scheduling::Booking.new(
        technician_id: technician_id,
        starts_at: Time.utc(2025, 3, 12, *starts_at),
        ends_at: Time.utc(2025, 3, 12, *ends_at),
        id: id
      )
    end

    test "hours are the exact duration" do
      assert_equal 2r, Scheduling.hours_between(Time.utc(2025, 3, 12, 9), Time.utc(2025, 3, 12, 11))
      assert_equal 1.5r, Scheduling.hours_between(Time.utc(2025, 3, 12, 13), Time.utc(2025, 3, 12, 14, 30))
      assert_equal 1r / 3, Scheduling.hours_between(Time.utc(2025, 3, 12, 9), Time.utc(2025, 3, 12, 9, 20))
      assert_equal 1r / 60, Scheduling.hours_between(Time.utc(2025, 3, 12, 9), Time.utc(2025, 3, 12, 9, 1))
    end

    test "weekend is judged in UTC" do
      assert Scheduling.weekend?(Time.utc(2025, 3, 15, 9))   # Saturday
      assert Scheduling.weekend?(Time.utc(2025, 3, 16, 23))  # Sunday
      assert_not Scheduling.weekend?(Time.utc(2025, 3, 14, 23)) # Friday
      assert_not Scheduling.weekend?(Time.utc(2025, 3, 17, 0))  # Monday

      # Friday evening in New York is already Saturday in UTC.
      friday_night_est = Time.new(2025, 3, 14, 23, 0, 0, "-05:00")
      assert Scheduling.weekend?(friday_night_est)
    end

    test "a window must end after it starts" do
      error = assert_raises ValidationFailed do
        Scheduling.check_window!(Time.utc(2025, 3, 12, 10), Time.utc(2025, 3, 12, 10))
      end
      assert_equal "appointment must end after it starts", error.message

      assert_raises ValidationFailed do
        Scheduling.check_window!(Time.utc(2025, 3, 12, 10), Time.utc(2025, 3, 12, 9))
      end
    end

    test "overlapping windows for one technician conflict" do
      existing = [ booking(id: 7, starts_at: [ 9 ], ends_at: [ 11 ]) ]

      candidate = booking(starts_at: [ 10 ], ends_at: [ 12 ])
      assert_equal 7, Scheduling.find_conflict(candidate, existing).id

      inside = booking(starts_at: [ 9, 30 ], ends_at: [ 10, 30 ])
      assert Scheduling.find_conflict(inside, existing)

      surrounding = booking(starts_at: [ 8 ], ends_at: [ 12 ])
      assert Scheduling.find_conflict(surrounding, existing)

      identical = booking(starts_at: [ 9 ], ends_at: [ 11 ])
      assert Scheduling.find_conflict(identical, existing)
    end

    test "touching endpoints do not conflict" do
      existing = [ booking(id: 7, starts_at: [ 9 ], ends_at: [ 10 ]) ]

      after = booking(starts_at: [ 10 ], ends_at: [ 11 ])
      assert_nil Scheduling.find_conflict(after, existing)

      before = booking(starts_at: [ 8 ], ends_at: [ 9 ])
      assert_nil Scheduling.find_conflict(before, existing)
    end

    test "another technician's bookings are not in the way" do
      existing = [ booking(technician_id: 2, id: 7, starts_at: [ 9 ], ends_at: [ 11 ]) ]
      candidate = booking(technician_id: 1, starts_at: [ 9 ], ends_at: [ 11 ])
      assert_nil Scheduling.find_conflict(candidate, existing)
    end

    test "a rescheduled booking does not conflict with itself" do
      existing = [ booking(id: 7, starts_at: [ 9 ], ends_at: [ 11 ]) ]
      moved = booking(id: 7, starts_at: [ 9, 30 ], ends_at: [ 11, 30 ])
      assert_nil Scheduling.find_conflict(moved, existing)

      # But it still conflicts with everyone else.
      existing << booking(id: 8, starts_at: [ 11 ], ends_at: [ 12 ])
      assert_equal 8, Scheduling.find_conflict(moved, existing).id
    end

    test "check_availability! raises the wire error" do
      existing = [ booking(id: 7, starts_at: [ 9 ], ends_at: [ 11 ]) ]
      candidate = booking(starts_at: [ 10 ], ends_at: [ 12 ])

      error = assert_raises ScheduleConflict do
        Scheduling.check_availability!(candidate, existing)
      end
      assert_equal "technician is already booked for that time", error.message

      Scheduling.check_availability!(booking(starts_at: [ 11 ], ends_at: [ 12 ]), existing)
    end
  end
end
