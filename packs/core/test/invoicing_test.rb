require "test_helper"

module Dispatch
  class InvoicingTest < ActiveSupport::TestCase
    test "only a completed job can be invoiced" do
      %w[requested scheduled in_progress cancelled].each do |status|
        error = assert_raises InvalidTransition do
          Invoicing.check_invoiceable!(status, already_invoiced: false)
        end
        assert_equal "only a completed job can be invoiced", error.message
      end

      Invoicing.check_invoiceable!("completed", already_invoiced: false)
    end

    test "the duplicate check runs before the status check" do
      # An invoiced job fails both rules; the duplicate must win because the
      # two errors carry different HTTP statuses.
      error = assert_raises ValidationFailed do
        Invoicing.check_invoiceable!("invoiced", already_invoiced: true)
      end
      assert_equal "job is already invoiced", error.message

      assert_raises ValidationFailed do
        Invoicing.check_invoiceable!("completed", already_invoiced: true)
      end
    end

    test "draft prices the job it was asked about" do
      labor = [
        Dispatch::Pricing::LaborItem.new(
          appointment_id: 1,
          technician_name: "Dana Reyes",
          hourly_cost_cents: 8000,
          starts_at: Time.utc(2025, 3, 12, 13),
          ends_at: Time.utc(2025, 3, 12, 14, 30)
        )
      ]

      priced = Invoicing.draft(status: "completed", priority: "normal", labor: labor, parts: [], already_invoiced: false)
      assert_equal 19200, priced.total_cents

      assert_raises InvalidTransition do
        Invoicing.draft(status: "in_progress", priority: "normal", labor: labor, parts: [], already_invoiced: false)
      end
    end
  end
end
