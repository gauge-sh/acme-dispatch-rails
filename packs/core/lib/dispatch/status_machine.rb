module Dispatch
  module StatusMachine
    STATUSES = %w[requested scheduled in_progress completed invoiced cancelled].freeze

    NEXT = {
      "requested" => %w[scheduled cancelled].freeze,
      "scheduled" => %w[in_progress cancelled].freeze,
      "in_progress" => %w[completed cancelled].freeze,
      "completed" => %w[invoiced].freeze,
      "invoiced" => [].freeze,
      "cancelled" => [].freeze
    }.freeze

    TERMINAL = %w[invoiced cancelled].freeze

    # Statuses a job can still take appointments in.
    OPEN_FOR_SCHEDULING = %w[requested scheduled in_progress].freeze

    module_function

    def status?(value) = STATUSES.include?(value)

    def allowed(from) = NEXT.fetch(from)

    def can_move?(from, to) = allowed(from).include?(to)

    def terminal?(status) = TERMINAL.include?(status)

    def accepts_appointments?(status) = OPEN_FOR_SCHEDULING.include?(status)

    # Guards the generic transition path. `invoiced` is part of the machine
    # but is never offered here: creating the invoice record is what moves a
    # completed job, so asking for it directly is always refused.
    def check_transition!(from, to, appointment_count:)
      if to == "invoiced" || !can_move?(from, to)
        raise InvalidTransition, "cannot move a job from #{from} to #{to}"
      end
      if to == "scheduled" && appointment_count < 1
        raise ValidationFailed, "a job needs an appointment before it can be scheduled"
      end
    end

    def check_accepts_appointments!(status)
      return if accepts_appointments?(status)

      raise ValidationFailed, "appointments cannot be added to a job that is #{status}"
    end
  end
end
