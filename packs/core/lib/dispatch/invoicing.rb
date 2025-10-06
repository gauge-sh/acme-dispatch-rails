module Dispatch
  module Invoicing
    module_function

    # A job that already has a record breaks both rules at once. The duplicate
    # wins so the caller hears about the record, not the status — the two map
    # to different HTTP statuses and the order is contractual.
    def check_invoiceable!(status, already_invoiced:)
      raise ValidationFailed, "job is already invoiced" if already_invoiced
      return if status == "completed"

      raise InvalidTransition, "only a completed job can be invoiced"
    end

    # Prices a completed job. The caller persists the result and moves the job
    # to `invoiced` in the same transaction.
    def draft(status:, priority:, labor:, parts:, already_invoiced:)
      check_invoiceable!(status, already_invoiced: already_invoiced)
      Pricing.price(priority: priority, labor: labor, parts: parts)
    end
  end
end
