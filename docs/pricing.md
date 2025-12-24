# Pricing

How an invoice record's numbers are produced. The authoritative statement of
these rules is `docs/domain.md` §Pricing and the conformance table in
`packs/core/test/fixtures/pricing-cases.json`; this page is the readable tour.

## Lines

**Labor** — one line per appointment:

```
hours × technician.hourly_cost_cents × 1.6
```

rounded to whole cents. `hours` is the exact duration of the appointment —
a 20-minute visit bills 1/3 of an hour, not a rounded 0.33. If the
appointment starts on a Saturday or Sunday *in UTC*, the already-rounded
line is multiplied by 1.15 and rounded again. The surcharge is per
appointment: a job with a Wednesday visit and a Sunday visit surcharges only
the Sunday line.

**Parts** — one line per job-part row:

```
quantity × unit_price_cents
```

Both factors are integers, so no rounding is involved. The price is the one
captured when the part was recorded on the job; changing the catalog price
later does not restate old invoices. Recording the same part twice keeps two
lines.

## Totals

```
labor_cents = sum of labor lines (surcharges included)
parts_cents = sum of part lines
total_cents = labor_cents + parts_cents
```

If the job's priority is `urgent`, the total — and only the total — is
multiplied by 1.10 and rounded. Line amounts are never restated by the
urgent multiplier. `low` and `normal` add nothing.

## Rounding

Round half away from zero, to whole cents, after each line computation and
after the urgent multiplier. This is not Ruby's default: `Float#round` and
`Integer#round` break ties to even, and float math can land a hair under the
half before rounding ever happens. `Dispatch::Money.round_cents` therefore
converts through an exact `Rational` and rounds with `half: :up`. The
multipliers themselves are rational literals (`1.6r`, `0.15r`, `0.1r`) so no
intermediate result ever touches a float.

Worked example (conformance case 4): 1.5h × 8000¢ × 1.6 = 19200¢ labor;
3 × 1299¢ = 3897¢ parts; total 23097¢; urgent 23097 × 1.1 = 25406.7 →
**25407¢**. Case 6 shows the down-rounding side: 0.5h × 3333¢ × 1.6 =
2666.4 → **2666¢**.

## Ordering

Line items are ordered: labor lines by `scheduled_start` ascending (ties by
appointment id), then part lines by job-part id. Labor descriptions render
the duration quantized to two decimals with trailing zeros stripped
(`2h`, `1.5h`, `0.33h`) — a display label only; the amount always uses the
exact duration.
