require "test_helper"

module Dispatch
  # Drives the shared conformance table in test/fixtures/pricing-cases.json.
  # Every implementation of the dispatch domain must produce these numbers.
  class PricingConformanceTest < ActiveSupport::TestCase
    FIXTURE = JSON.parse(File.read(File.expand_path("fixtures/pricing-cases.json", __dir__)))

    test "the fixture pins the shared multipliers" do
      # JSON parses the multipliers as floats; going through the decimal
      # string keeps the comparison exact.
      assert_equal Pricing::LABOR_MARKUP, FIXTURE.fetch("labor_markup").to_s.to_r
      assert_equal Pricing::WEEKEND_SURCHARGE, FIXTURE.fetch("weekend_surcharge").to_s.to_r
      assert_equal Pricing::URGENT_SURCHARGE, FIXTURE.fetch("urgent_surcharge").to_s.to_r
    end

    FIXTURE.fetch("cases").each do |kase|
      test "case #{kase.fetch("id")}: #{kase.fetch("name")}" do
        labor = kase.fetch("appointments").map.with_index(1) do |appointment, index|
          starts_at = Time.iso8601(appointment.fetch("start"))
          ends_at = Time.iso8601(appointment.fetch("end"))

          # The fixture's derived columns must agree with our own math before
          # we trust its expectations.
          assert_equal appointment.fetch("hours").to_r, Scheduling.hours_between(starts_at, ends_at)
          assert_equal appointment.fetch("weekend"), Scheduling.weekend?(starts_at)

          Pricing::LaborItem.new(
            appointment_id: index,
            technician_name: "Tech #{index}",
            hourly_cost_cents: appointment.fetch("technician_hourly_cost_cents"),
            starts_at: starts_at,
            ends_at: ends_at
          )
        end

        parts = kase.fetch("parts").map.with_index(1) do |part, index|
          Pricing::PartItem.new(
            job_part_id: index,
            sku: "SKU-#{index}",
            name: "Part #{index}",
            quantity: part.fetch("quantity"),
            unit_price_cents: part.fetch("unit_price_cents")
          )
        end

        priced = Pricing.price(priority: kase.fetch("priority"), labor: labor, parts: parts)

        expected = kase.fetch("expected")
        assert_equal expected.fetch("labor_cents"), priced.labor_cents
        assert_equal expected.fetch("parts_cents"), priced.parts_cents
        assert_equal expected.fetch("total_cents"), priced.total_cents
      end
    end
  end
end
