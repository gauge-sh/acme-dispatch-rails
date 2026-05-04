# Acme Dispatch

Field-service operations for a small shop: office staff log jobs, schedule
technicians, track the parts that went out the door, and record what to bill.
It is an internal tool — users are created by an admin, and the "invoice" is
a record of amounts, not a payment flow.

## Quickstart

```
bin/setup --skip-server
bin/rails db:seed
bin/rails server
```

Then sign in at <http://localhost:3000> as `admin@acme-dispatch.example` with
password `dispatch-dev-1`. Seeds are deterministic, so everyone's demo data
is the same.

Run the whole test suite with:

```
bin/rails test test packs
```

## Layout

| Path | What lives there |
|---|---|
| `packs/core` | The domain as plain Ruby: status machine, scheduling conflicts, stock rules, pricing. No Rails imports; most unit tests live here. |
| `packs/api` | The JSON API engine at `/api/v1` — bearer-token auth, the wire shapes from `docs/domain.md`. |
| `packs/web` | The server-rendered UI: dispatch board, jobs, scheduling, customers, technicians, parts and stock, invoice records, user admin. |
| `app/`, `db/` | Active Record models shared by both surfaces, migrations, deterministic seeds. |

Package boundaries are real — packwerk checks them in CI. The reasoning
behind the split is in `docs/architecture.md`, the billing math in
`docs/pricing.md`, day-to-day commands in `docs/runbook.md`, and the
field-level behavioral contract in `docs/domain.md`.

## License

MIT — see `LICENSE`.
