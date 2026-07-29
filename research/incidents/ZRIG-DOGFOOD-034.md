# ZRIG-DOGFOOD-034 — concurrent WS must share one in-process meter

## Context

V18 persisted meter to disk, but each `/ws` Session still owned its own
in-memory totals and raced `session_meter.json` on concurrent tabs.

## Friction

F-ZRIG-035 — process-wide `Shared` meter + ask receipt cost fields.

## Fix

- `session_meter.Shared` (`Io.Mutex`) allocated once in `web.serve`
- Sessions set `shared_meter`; `initialize` reports `shared_meter:true`
- Ask receipt schema 0.0.2: tokens + `cost_usd`
- Docs: `docs/V19.md`
