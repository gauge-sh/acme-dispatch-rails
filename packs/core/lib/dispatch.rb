# The domain rules for Acme Dispatch, free of Rails and persistence. Models
# and controllers call in; nothing in here calls out.
module Dispatch
  # Raised when a caller breaks a domain rule. `code` is the value the API
  # layer puts on the wire; the web layer maps these onto form errors.
  class Error < StandardError
    attr_reader :fields

    def initialize(message, fields: {})
      super(message)
      @fields = fields
    end
  end

  class ValidationFailed < Error
    def code = "validation_failed"
  end

  class InvalidTransition < Error
    def code = "invalid_transition"
  end

  class ScheduleConflict < Error
    def code = "schedule_conflict"
  end

  class InsufficientStock < Error
    def code = "insufficient_stock"
  end
end
