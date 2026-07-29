# ZRIG-DOGFOOD-035 — multi-tab meter needs live fanout

## Context

V19 shared one in-process meter, but only the Session that applied usage
pushed `message.usage`. Idle tabs kept a stale SPA badge until reconnect.

## Friction

F-ZRIG-036 — subscribe WS sinks to Shared; broadcast `meter.update`.

## Fix

- `FanoutSink` list on `session_meter.Shared`
- `/ws` subscribe/unsubscribe around connection lifetime
- Agent receipts: `duration_ms` / `total_duration_ms` (schema 0.0.2)
- Docs: `docs/V20.md`
