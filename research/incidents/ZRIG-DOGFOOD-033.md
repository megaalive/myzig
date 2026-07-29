# ZRIG-DOGFOOD-033 — session meter must persist across WS reconnects

## Context

V17 metered cost in-process. Web creates a new `Session` per `/ws` connection,
so refresh/reconnect zeroed the badge and forgot `budget_stopped`.

## Friction

F-ZRIG-034 — file-backed meter + `meter.reset` + SPA badge.

## Fix

- `.zrig/session_meter.json` via `session_meter.zig`
- `initialize` reports totals / `meter_persist`
- Docs: `docs/V18.md`
