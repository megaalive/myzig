# ZRIG-DOGFOOD-046 — read-only sub-agents

## Context

fpagnt 0.2.0 fans out `/subagents a || b` with read-only isolation. zrig V32
matches CLI fan-out + ordered merge + IsolationDenied for write/net/proc tools.

## Do

Split on `||`. Expect `subagent.started`/`completed` on stderr and ordered JSON
tasks on stdout. Never allow writes inside a child turn.

## Friction tip

`F-ZRIG-048` / `docs/V32.md`.
