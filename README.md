# myzig

A deterministic safety coach for Zig code and coding agents.

myzig focuses on **ownership reasoning and evidence**: obligations, honest certainty,
structured repair choices, and auditable receipts — while keeping ordinary Zig
first-class (no mandatory imports, no dialect, no ReleaseFast tax).

Beside the ownership coach, **`myzig.compat`** offers a narrow façade over
high-churn Zig std surfaces (fs/dir/env/path/time) so dogfood apps like zrig do
not rewrite call sites on every toolchain bump. Current ruleset revision:
`0.0.0-seed25`.

## Build

Requires a recent Zig 0.17 development toolchain.

```text
zig build
zig build test
zig build run -- --help
powershell -File scripts/ci.ps1    # local/agent CI parity (fmt + build + test + CLI smoke)
```

GitHub Actions is the forge gate (ubuntu by default; full OS matrix via
`workflow_dispatch` → `full_matrix`). Use `powershell -File scripts/ci.ps1` for
the same smoke offline or in agent loops; it matches `.github/workflows/ci.yml`.

## Library highlights

```zig
const myzig = @import("myzig");

// Coach schemas
_ = myzig.schema.seed_alloc_undischarged;

// Std insulation — prefer over raw std.Io.Dir / env / time
const data = try myzig.compat.readFileAlloc(io, gpa, "file.txt", 1024 * 1024);
defer gpa.free(data);
```

## CLI

```text
myzig check [path] [--ratchet] [--prefer-compat] [--sarif] [--receipt]
myzig explain <file:line> [--json|--agent]
myzig explain --rule <id> [--json|--agent]
myzig adopt [path]           # editable .myzig/policy.md + baseline if missing
myzig baseline [path]        # snapshot findings for ratchet
myzig friction [--sources]   # living text tips; update without new Zig code
myzig limits [--sources]     # published honest detector ceilings
myzig agent [--full]         # agent contract (+ limits/friction/rules)
myzig rules [--json|--markdown|--agent|--sarif]
myzig receipt [path]
myzig verify-cost <case>
myzig verify-cost --list
myzig init
```

Ratchet: after `myzig baseline`, CI can run `myzig check --ratchet <path>` to reject **new** debt while accepting the snapshot.

SARIF: `myzig check --sarif` emits forge-oriented SARIF 2.1.0 (suitable for GitHub code scanning upload).

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
