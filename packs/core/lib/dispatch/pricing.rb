module Dispatch
  module Pricing
    # Multipliers are exact rationals so intermediate math never touches a
    # float; rounding happens once per line, through Money.round_cents.
    LABOR_MARKUP = 1.6r
    WEEKEND_SURCHARGE = 0.15r
    URGENT_SURCHARGE = 0.1r

    LaborItem = Data.define(:appointment_id, :technician_name, :hourly_cost_cents, :starts_at, :ends_at) do
      def hours = Scheduling.hours_between(starts_at, ends_at)

      def weekend? = Scheduling.weekend?(starts_at)
    end

    PartItem = Data.define(:job_part_id, :sku, :name, :quantity, :unit_price_cents)

    LineItem = Data.define(:kind, :description, :quantity, :unit_cents, :amount_cents, :weekend)

    Priced = Data.define(:labor_cents, :parts_cents, :total_cents, :line_items)

    module_function

    def labor_amount(item)
      base = Money.round_cents(item.hours * item.hourly_cost_cents * LABOR_MARKUP)
      return base unless item.weekend?

      # The surcharge lands on the already-rounded line — two visible rounding
      # steps, per the pricing contract, not one on the raw product.
      Money.round_cents(base * (1 + WEEKEND_SURCHARGE))
    end

    def part_amount(item)
      item.quantity * item.unit_price_cents
    end

    # Hours as they read on an invoice: "2", "1.5", "0.25". Two decimals is
    # the finest granularity worth printing; amounts always come from the
    # exact duration, so the label never drives a total.
    def format_hours(hours)
      format("%.2f", hours.round(2, half: :up)).sub(/\.?0+\z/, "")
    end

    def labor_line(item)
      day = item.starts_at.getutc.strftime("%Y-%m-%d")
      LineItem.new(
        kind: "labor",
        description: "#{item.technician_name} — #{format_hours(item.hours)}h on #{day}",
        quantity: item.hours,
        unit_cents: item.hourly_cost_cents,
        amount_cents: labor_amount(item),
        weekend: item.weekend?
      )
    end

    def part_line(item)
      LineItem.new(
        kind: "part",
        description: "#{item.sku} — #{item.name}",
        quantity: item.quantity,
        unit_cents: item.unit_price_cents,
        amount_cents: part_amount(item),
        weekend: false
      )
    end

    def price(priority:, labor:, parts:)
      labor_lines = labor
        .sort_by { |item| [ item.starts_at, item.appointment_id ] }
        .map { |item| labor_line(item) }
      part_lines = parts.sort_by(&:job_part_id).map { |item| part_line(item) }

      labor_cents = labor_lines.sum(&:amount_cents)
      parts_cents = part_lines.sum(&:amount_cents)
      total_cents = labor_cents + parts_cents
      if priority == "urgent"
        # Applied last and to the total alone; the line amounts stay as billed.
        total_cents = Money.round_cents(total_cents * (1 + URGENT_SURCHARGE))
      end

      Priced.new(
        labor_cents: labor_cents,
        parts_cents: parts_cents,
        total_cents: total_cents,
        line_items: labor_lines + part_lines
      )
    end
  end
end
