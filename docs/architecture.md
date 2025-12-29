# Architecture

One Rails application, three packwerk packages plus the host. The boundaries
are enforced — `bin/bundle exec packwerk check` runs in CI and fails the build
on a violation.

## Packages

### `packs/core`

The domain, as plain Ruby: the job status machine, the appointment overlap
rule, stock arithmetic, and pricing. No Rails, no Active Record, no HTTP —
`package.yml` declares zero dependencies, so nothing in here can reach out.
Everything money-shaped is an integer number of cents; everything fractional
travels as a `Rational` until `Dispatch::Money.round_cents` rounds it, half
away from zero.

Core also owns the error taxonomy (`Dispatch::ValidationFailed`,
`InvalidTransition`, `ScheduleConflict`, `InsufficientStock`). Both HTTP
surfaces translate those errors mechanically, which is what keeps the API's
wire codes and the web's flash messages saying the same thing.

The pricing conformance table lives at `packs/core/test/fixtures/pricing-cases.json`
and drives one parameterized test. If pricing behavior and that file disagree,
the file wins; fix the code.

### The host (root package)

Active Record models, migrations, seeds, and configuration. Models depend on
core and delegate every rule to it: `Job#transition_to!` asks the status
machine, `Appointment` asks the scheduler, `StockLevel` asks the stock module.
The host depends on core and nothing else; it does not know the API or web
packages exist.

### `packs/api`

A mounted Rails engine serving `/api/v1` — the contract in `docs/domain.md`.
Bearer-token auth against `ApiToken` digests, a single `Api::Wire` serializer
module that owns the exact JSON shapes (hash insertion order is the wire key
order), and controllers thin enough to read in one sitting. The engine mounts
itself from an initializer so the host's routes file never references an
engine constant.

### `packs/web`

The server-rendered UI: controllers, helpers, ERB views, and one hand-written
stylesheet. No JavaScript framework, no component library — forms post, pages
reload. The host wires the pack's `app/*` directories into the autoload and
view paths in `config/application.rb`.

## Dependency graph

```
packs/api ──▶ host ──▶ packs/core
packs/web ──▶ host ──▶ packs/core
packs/api ──────────▶ packs/core
packs/web ──────────▶ packs/core
```

No cycles: the host never references api or web constants (routes name web
controllers as strings; the engine mounts itself).

## Where a rule lives

- If it is true of the domain no matter who is asking (legal transitions,
  overlap, rounding): `packs/core`.
- If it needs persistence context (does this technician have appointments,
  is this the last active admin): a model, raising core's errors so both
  surfaces behave alike.
- If it needs to know who is asking (admins only, you cannot deactivate
  yourself): the controller layer, in both packs, with the model as backstop
  where lockout is possible.
