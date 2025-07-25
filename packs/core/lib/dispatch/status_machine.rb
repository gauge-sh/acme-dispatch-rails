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

    module_function

    def status?(value) = STATUSES.include?(value)

    def allowed(from) = NEXT.fetch(from)

    def can_move?(from, to) = allowed(from).include?(to)

    def terminal?(status) = TERMINAL.include?(status)

    # Guards the generic transition path. `invoiced` is part of the machine
    # but is never offered here: creating the invoice record is what moves a
    # completed job, so asking for it directly is always refused.
    def check_transition!(from, to)
      if to == "invoiced" || !can_move?(from, to)
        raise InvalidTransition, "cannot move a job from #{from} to #{to}"
      end
    end
  end
end
