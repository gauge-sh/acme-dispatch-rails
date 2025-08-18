module Dispatch
  module Scheduling
    SECONDS_PER_HOUR = 3600r

    Booking = Data.define(:technician_id, :starts_at, :ends_at, :id) do
      def initialize(technician_id:, starts_at:, ends_at:, id: nil)
        super
      end
    end

    module_function

    # Exact decimal hours between two moments. Labor bills the real duration:
    # no quarter-hour steps, no minimum, and no float that could push a line
    # onto the wrong side of a half cent.
    def hours_between(starts_at, ends_at)
      (ends_at.to_r - starts_at.to_r) / SECONDS_PER_HOUR
    end

    # Saturday or Sunday in UTC, whatever zone the caller hands us.
    def weekend?(moment)
      moment.getutc.saturday? || moment.getutc.sunday?
    end

    def check_window!(starts_at, ends_at)
      return if ends_at > starts_at

      raise ValidationFailed, "appointment must end after it starts"
    end

    # Overlap is half-open [start, end): back-to-back appointments touch but
    # do not collide.
    def overlap?(first, second)
      first.starts_at < second.ends_at && second.starts_at < first.ends_at
    end

    def find_conflict(candidate, existing)
      existing.find do |booked|
        next false unless booked.technician_id == candidate.technician_id
        # A booking being rescheduled is passed in with everything else; it is
        # not in the way of itself.
        next false if candidate.id && booked.id == candidate.id

        overlap?(candidate, booked)
      end
    end

    def check_availability!(candidate, existing)
      check_window!(candidate.starts_at, candidate.ends_at)
      return unless find_conflict(candidate, existing)

      raise ScheduleConflict, "technician is already booked for that time"
    end
  end
end
