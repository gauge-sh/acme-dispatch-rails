class Appointment < ApplicationRecord
  belongs_to :job
  belongs_to :technician

  normalizes :completion_notes, with: ->(value) { value.strip.presence }

  validates :scheduled_start, :scheduled_end, presence: true
  validates :completion_notes, length: { maximum: 2000 }, allow_nil: true

  before_save :enforce_scheduling_rules

  def hours = Dispatch::Scheduling.hours_between(scheduled_start, scheduled_end)

  def weekend? = Dispatch::Scheduling.weekend?(scheduled_start)

  def to_booking
    Dispatch::Scheduling::Booking.new(
      technician_id: technician_id,
      starts_at: scheduled_start,
      ends_at: scheduled_end,
      id: id
    )
  end

  private

  def enforce_scheduling_rules
    candidate = to_booking
    # The SQL window is the same half-open overlap the domain applies; core
    # gets only the rows that could possibly collide.
    others = Appointment.where(technician_id: technician_id)
      .where("scheduled_start < ? AND scheduled_end > ?", scheduled_end, scheduled_start)
      .where.not(id: id)
    Dispatch::Scheduling.check_availability!(candidate, others.map(&:to_booking))
  end
end
