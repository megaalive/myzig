# myzig

A deterministic safety coach for Zig code and coding agents.

myzig focuses on **ownership reasoning and evidence**: obligations, honest certainty,
structured repair choices, and auditable receipts — while keeping ordinary Zig
first-class (no mandatory imports, no dialect, no ReleaseFast tax).

This repository is early scaffolding. Beside the ownership coach, **`myzig.compat`**
offers a narrow façade over high-churn Zig std surfaces (fs/dir/env/path/time) so
dogfood apps like zrig do not rewrite call sites on every toolchain bump.

## Build

Requires a recent Zig 0.17 development toolchain.

```text
zig build
zig build test
zig build run -- --help
```

## Library highlights

```zig
const myzig = @import("myzig");

// Coach schemas (M0)
_ = myzig.schema.seed_alloc_undischarged;

// Std insulation (M0b) — prefer over raw std.Io.Dir / env / time
const data = try myzig.compat.readFileAlloc(io, gpa, "file.txt", 1024 * 1024);
defer gpa.free(data);
```

## CLI

```text
myzig check [path] [--ratchet]
myzig explain <file:line> [--json|--agent]
myzig explain --rule <id> [--json|--agent]
myzig adopt [path]           # editable .myzig/policy.md + baseline if missing
myzig baseline [path]        # snapshot findings for ratchet
myzig friction [--sources]   # living text tips; update without new Zig code
myzig rules [--json|--markdown|--agent|--sarif]
myzig receipt [path]
myzig verify-cost <case>
myzig verify-cost --list
myzig init
```

Ratchet: after `myzig baseline`, CI can run `myzig check --ratchet <path>` to reject **new** debt while accepting the snapshot.

Cost witnesses: `myzig verify-cost id-passthrough` writes `.myzig/cost-witnesses/…`; only then may `myzig receipt` include `claimed.verify_cost`.

## Layout

| Path | Role |
|------|------|
| `src/` | Library (`myzig`) and CLI |
| `spec/` | Rule catalog source of truth (`.zon`) |
| `fixtures/` | Ordinary-Zig pass/fail examples |
| `research/incidents/` | Incident lab notes (dogfood dataset) |

Project config lives in `.myzig/` after `myzig init`.

## Identity

```text
deterministic · honest · auditable
```

Helpers and wrappers arrive only when incidents and cost witnesses justify them.
