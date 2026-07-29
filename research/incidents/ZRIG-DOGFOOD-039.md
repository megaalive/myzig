# ZRIG-DOGFOOD-039 — SPA wiped prior turns on each ask

## Context

Web UI cleared `#out` on every ask with no history panel, so multi-ask sessions
lost prior answers after refresh/reconnect of the live pane.

## Friction

F-ZRIG-040 — turn history + sessionStorage + clear control.

## Fix

- `#hist` / `clearHist` in `web` index HTML
- `/api/meta` `spa_history: true`
- Docs: `docs/V24.md`
