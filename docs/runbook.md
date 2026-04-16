# Runbook

## Requirements

Ruby 3.2.3 (see `.ruby-version`). SQLite ships with the `sqlite3` gem — no
external services of any kind.

## First run

```
bin/setup --skip-server
bin/rails db:seed
bin/rails server
```

`bin/setup` bundles and prepares the database. Seeding is deterministic: it
wipes the dispatch tables and rebuilds the same 20 customers, 8 technicians,
40 jobs, 25 parts and 7 invoice records every time, and prints a fresh API
token for the seeded admin.

Sign in at <http://localhost:3000> as `admin@acme-dispatch.example` /
`dispatch-dev-1` (or `dispatch@acme-dispatch.example` for the dispatcher
view).

## Tests

```
bin/rails test test packs
```

runs everything: core unit tests in `packs/core/test`, API integration tests
in `packs/api/test`, web tests in `packs/web/test`, and model tests in
`test/`. The suite needs no network and finishes in well under a minute.

## Lint and boundaries

```
bin/rubocop
bin/packwerk check
```

Both run in CI. Packwerk enforces the package graph described in
`docs/architecture.md`.

## The API

All endpoints sit under `/api/v1` and require `Authorization: Bearer <token>`.
Tokens are issued per user from the web app (Users → user → "Issue a token");
the plaintext is shown once and only a SHA-256 digest is stored. To try it:

```
curl -H "Authorization: Bearer $TOKEN" "localhost:3000/api/v1/jobs?status=requested"

curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"status": "scheduled"}' localhost:3000/api/v1/jobs/12/transition

curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"delta": -2}' localhost:3000/api/v1/stock-levels/7/adjust
```

Errors come back as `{"error": {"code", "message"}}` with the codes and
messages specified in `docs/domain.md`; conflicts (double bookings, stock
going negative, illegal transitions) are 409s.

## Production notes

This is an internal tool. Run it like any small Rails app: set
`SECRET_KEY_BASE`, point `RAILS_ENV=production` at a persistent disk for
`db/production.sqlite3`, and run the migrations. There is no queue, mailer,
or cache dependency to provision.
