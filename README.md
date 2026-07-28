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
myzig check [path]
myzig explain <file:line>
myzig friction [--sources]   # living text tips; update without new Zig code
myzig adopt [path]
myzig baseline
myzig rules [--json|--markdown|--agent|--sarif]
myzig receipt [path]
myzig verify-cost <case>
myzig init
```

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
