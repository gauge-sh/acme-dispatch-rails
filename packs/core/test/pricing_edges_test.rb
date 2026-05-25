require "test_helper"

module Dispatch
  # Rounding interactions the conformance table does not reach: stacked
  # surcharges, sub-cent lines, and many-line accumulation.
  class PricingEdgesTest < ActiveSupport::TestCase
    def labor_item(id: 1, rate:, starts_at:, minutes:)
      Pricing::LaborItem.new(
        appointment_id: id,
        technician_name: "Edge Tech",
        hourly_cost_cents: rate,
        starts_at: starts_at,
        ends_at: starts_at + minutes * 60
      )
    end

    test "a weekend urgent job rounds three times, in order" do
      # 0.5h * 3333 * 1.6 = 2666.4 -> 2666; * 1.15 = 3065.9 -> 3066;
      # urgent: 3066 * 1.1 = 3372.6 -> 3373. Rounding the raw product once
      # would give a different total.
      item = labor_item(rate: 3333, starts_at: Time.utc(2025, 3, 15, 8), minutes: 30)
      priced = Pricing.price(priority: "urgent", labor: [ item ], parts: [])

      assert_equal 3066, priced.labor_cents
      assert_equal 3373, priced.total_cents
    end

    test "one minute of labor still bills" do
      item = labor_item(rate: 6000, starts_at: Time.utc(2025, 3, 12, 8), minutes: 1)
      line = Pricing.labor_line(item)

      # 1/60 h * 6000 * 1.6 = 160 exactly.
      assert_equal 160, line.amount_cents
      assert_equal "Edge Tech — 0.02h on 2025-03-12", line.description
    end

    test "line rounding does not accumulate across many lines" do
      # Ten lines of 2666.4 raw cents each: rounded per line the total is
      # 26660, not round(26664) = 26664.
      items = (1..10).map do |id|
        labor_item(id: id, rate: 3333, starts_at: Time.utc(2025, 3, 12, 8) + id * 3600, minutes: 30)
      end
      priced = Pricing.price(priority: "normal", labor: items, parts: [])

      assert_equal 26660, priced.labor_cents
    end

    test "parts sum exactly regardless of quantity" do
      parts = [
        Pricing::PartItem.new(job_part_id: 1, sku: "A-1", name: "a", quantity: 7, unit_price_cents: 333),
        Pricing::PartItem.new(job_part_id: 2, sku: "B-2", name: "b", quantity: 13, unit_price_cents: 101)
      ]
      priced = Pricing.price(priority: "normal", labor: [], parts: parts)

      assert_equal 7 * 333 + 13 * 101, priced.parts_cents
      assert_equal priced.parts_cents, priced.total_cents
    end

    test "urgent applies to labor plus parts, after both" do
      labor = [ labor_item(rate: 3333, starts_at: Time.utc(2025, 3, 12, 8), minutes: 30) ]
      parts = [ Pricing::PartItem.new(job_part_id: 1, sku: "A-1", name: "a", quantity: 1, unit_price_cents: 101) ]
      priced = Pricing.price(priority: "urgent", labor: labor, parts: parts)

      # (2666 + 101) * 1.1 = 3043.7 -> 3044
      assert_equal 3044, priced.total_cents
    end

    test "the weekend flag follows the start, not the end" do
      # Friday 23:30 UTC to Saturday 00:30 UTC is a weekday line.
      friday_night = labor_item(rate: 6000, starts_at: Time.utc(2025, 3, 14, 23, 30), minutes: 60)
      assert_not Pricing.labor_line(friday_night).weekend

      # Sunday 23:30 UTC to Monday 00:30 UTC keeps the surcharge.
      sunday_night = labor_item(rate: 6000, starts_at: Time.utc(2025, 3, 16, 23, 30), minutes: 60)
      assert Pricing.labor_line(sunday_night).weekend
    end
  end
end
