require "test_helper"

module Dispatch
  class PricingTest < ActiveSupport::TestCase
    def labor_item(id: 1, name: "Dana Reyes", rate: 8000, starts_at:, ends_at:)
      Pricing::LaborItem.new(
        appointment_id: id,
        technician_name: name,
        hourly_cost_cents: rate,
        starts_at: starts_at,
        ends_at: ends_at
      )
    end

    test "a weekday labor line is hours times rate times markup" do
      item = labor_item(starts_at: Time.utc(2025, 3, 12, 13), ends_at: Time.utc(2025, 3, 12, 14, 30))
      line = Pricing.labor_line(item)

      assert_equal "labor", line.kind
      assert_equal "Dana Reyes — 1.5h on 2025-03-12", line.description
      assert_equal 1.5r, line.quantity
      assert_equal 8000, line.unit_cents
      assert_equal 19200, line.amount_cents
      assert_not line.weekend
    end

    test "a weekend labor line surcharges the rounded base" do
      item = labor_item(rate: 5000, starts_at: Time.utc(2025, 3, 15, 9), ends_at: Time.utc(2025, 3, 15, 11))
      line = Pricing.labor_line(item)

      assert line.weekend
      assert_equal 18400, line.amount_cents

      # An odd rate rounds once before the surcharge and once after.
      odd = labor_item(rate: 3333, starts_at: Time.utc(2025, 3, 15, 8), ends_at: Time.utc(2025, 3, 15, 8, 30))
      assert_equal Money.round_cents(2666 * 1.15r), Pricing.labor_line(odd).amount_cents
    end

    test "hour labels read like an invoice" do
      [
        [ 2r, "2" ],
        [ 1.5r, "1.5" ],
        [ 1r, "1" ],
        [ 0.25r, "0.25" ],
        [ 1r / 3, "0.33" ],
        [ 0.3r, "0.3" ],
        [ 1r / 60, "0.02" ]
      ].each do |hours, label|
        assert_equal label, Pricing.format_hours(hours), hours.inspect
      end
    end

    test "a twenty minute visit bills a third of an hour, not the label" do
      item = labor_item(rate: 9000, starts_at: Time.utc(2025, 3, 12, 9), ends_at: Time.utc(2025, 3, 12, 9, 20))
      line = Pricing.labor_line(item)

      assert_equal "Dana Reyes — 0.33h on 2025-03-12", line.description
      assert_equal Money.round_cents(1r / 3 * 9000 * 1.6r), line.amount_cents
      assert_equal 4800, line.amount_cents
    end

    test "part lines are exact" do
      item = Pricing::PartItem.new(job_part_id: 18, sku: "IGN-4420", name: "Hot surface igniter", quantity: 3, unit_price_cents: 1299)
      line = Pricing.part_line(item)

      assert_equal "part", line.kind
      assert_equal "IGN-4420 — Hot surface igniter", line.description
      assert_equal 3, line.quantity
      assert_equal 1299, line.unit_cents
      assert_equal 3897, line.amount_cents
      assert_not line.weekend
    end

    test "labor lines sort by start then appointment id, parts by job part id" do
      nine = Time.utc(2025, 3, 12, 9)
      labor = [
        labor_item(id: 5, starts_at: Time.utc(2025, 3, 12, 13), ends_at: Time.utc(2025, 3, 12, 14)),
        labor_item(id: 4, starts_at: nine, ends_at: Time.utc(2025, 3, 12, 10)),
        labor_item(id: 2, starts_at: nine, ends_at: Time.utc(2025, 3, 12, 11))
      ]
      parts = [
        Pricing::PartItem.new(job_part_id: 9, sku: "B", name: "b", quantity: 1, unit_price_cents: 100),
        Pricing::PartItem.new(job_part_id: 3, sku: "A", name: "a", quantity: 1, unit_price_cents: 100)
      ]

      priced = Pricing.price(priority: "normal", labor: labor, parts: parts)

      assert_equal %w[labor labor labor part part], priced.line_items.map(&:kind)
      assert_equal [ 2, 4, 5 ].map { |id| labor.find { |item| item.appointment_id == id } }.map(&:hours),
        priced.line_items.first(3).map(&:quantity)
      assert_equal %w[A B], priced.line_items.last(2).map { |line| line.description[0] }
    end

    test "urgent multiplies the rounded total, never the lines" do
      labor = [ labor_item(starts_at: Time.utc(2025, 3, 12, 13), ends_at: Time.utc(2025, 3, 12, 14, 30)) ]
      parts = [ Pricing::PartItem.new(job_part_id: 1, sku: "IGN-4420", name: "igniter", quantity: 3, unit_price_cents: 1299) ]

      normal = Pricing.price(priority: "normal", labor: labor, parts: parts)
      urgent = Pricing.price(priority: "urgent", labor: labor, parts: parts)

      assert_equal 23097, normal.total_cents
      assert_equal 25407, urgent.total_cents
      assert_equal normal.labor_cents, urgent.labor_cents
      assert_equal normal.parts_cents, urgent.parts_cents
      assert_equal normal.line_items, urgent.line_items
    end

    test "low priority takes no multiplier" do
      labor = [ labor_item(starts_at: Time.utc(2025, 3, 12, 13), ends_at: Time.utc(2025, 3, 12, 14, 30)) ]
      priced = Pricing.price(priority: "low", labor: labor, parts: [])
      assert_equal priced.labor_cents, priced.total_cents
    end

    test "an empty job prices to zero" do
      priced = Pricing.price(priority: "urgent", labor: [], parts: [])
      assert_equal 0, priced.labor_cents
      assert_equal 0, priced.parts_cents
      assert_equal 0, priced.total_cents
      assert_empty priced.line_items
    end
  end
end
