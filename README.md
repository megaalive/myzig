# myzig

A deterministic safety coach for Zig code and coding agents.

myzig focuses on **ownership reasoning and evidence**: obligations, honest certainty,
structured repair choices, and auditable receipts — while keeping ordinary Zig
first-class (no mandatory imports, no dialect, no ReleaseFast tax).

This repository is early scaffolding. The first product milestone is one real
defect loop (rule → explain → repair → fixtures → agent receipt), not a large
checker catalog.

## Build

Requires a recent Zig 0.17 development toolchain.

```text
zig build
zig build test
zig build run -- --help
```

## CLI (stubs)

```text
myzig check [path]
myzig explain <file:line>
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
